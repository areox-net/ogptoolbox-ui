module Authenticator.SignIn.State exposing (..)

import Authenticator.SignIn.Types exposing (..)
import Configuration exposing (apiUrl)
import Decoders
import Dict exposing (Dict)
import Http
import Json.Encode
import Ports
import Types exposing (User)


init : Model
init =
    { httpError = Nothing
    , errors = Dict.empty
    , password = ""
    , username = ""
    }


update : InternalMsg -> Model -> ( Model, Cmd Msg, Maybe User )
update msg model =
    case msg of
        PasswordInput text ->
            ( { model | password = text }, Cmd.none, Nothing )

        SignedIn response ->
            case response of
                Result.Err err ->
                    let
                        _ =
                            Debug.log "Authenticator.SignedIn Error" err
                    in
                        ( model, Cmd.none, Nothing )

                Result.Ok body ->
                    let
                        user =
                            Just body.data
                    in
                        ( { model | httpError = Nothing }
                        , Ports.storeAuthentication (Ports.userToUserForPort user)
                        , user
                        )

        Submit ->
            let
                errorsList =
                    (List.filterMap
                        (\( name, errorMaybe ) ->
                            case errorMaybe of
                                Just error ->
                                    Just ( name, error )

                                Nothing ->
                                    Nothing
                        )
                        [ ( "password"
                          , if String.isEmpty model.password then
                                Just "Missing password"
                            else
                                Nothing
                          )
                        , ( "username"
                          , if String.isEmpty model.username then
                                Just "Missing username"
                            else
                                Nothing
                          )
                        ]
                    )

                cmd =
                    if List.isEmpty errorsList then
                        let
                            bodyJson =
                                Json.Encode.object
                                    [ ( "userName", Json.Encode.string model.username )
                                    , ( "password", Json.Encode.string model.password )
                                    ]
                        in
                            Http.post
                                (apiUrl ++ "login")
                                (Http.stringBody "application/json" <| Json.Encode.encode 2 bodyJson)
                                Decoders.userBodyDecoder
                                |> Http.send (ForSelf << SignedIn)
                    else
                        Cmd.none
            in
                ( { model | errors = Dict.fromList errorsList }, cmd, Nothing )

        UsernameInput text ->
            ( { model | username = text }, Cmd.none, Nothing )
