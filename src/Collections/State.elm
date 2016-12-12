module Collections.State exposing (..)

import Authenticator.Model
import Constants
import I18n exposing (getImageUrlOrOgpLogo, getName)
import Ports
import Requests
import Task
import Collections.Types exposing (..)
import WebData exposing (..)


init : Model
init =
    { collections = NotAsked }


update : InternalMsg -> Model -> Maybe Authenticator.Model.Authentication -> I18n.Language -> ( Model, Cmd Msg )
update msg model authentication language =
    case msg of
        LoadCollections ->
            let
                newModel =
                    { model | collections = Data (Loading Nothing) }

                cmd =
                    Task.perform
                        LoadCollectionsError
                        LoadCollectionsSuccess
                        (Requests.getCollections authentication Nothing)
                        |> Cmd.map ForSelf
            in
                ( newModel, cmd )

        LoadCollectionsError err ->
            let
                _ =
                    Debug.log "Collections.State LoadCollectionsError" err

                newModel =
                    { model | collections = Failure err }
            in
                ( newModel, Cmd.none )

        LoadCollectionsSuccess body ->
            let
                newModel =
                    { model | collections = Data (Loaded body) }

                cmd =
                    Ports.setDocumentMetatags
                        { title =
                            "Collections"
                            -- TODO i18n
                        , imageUrl = Constants.logoUrl
                        }
            in
                ( newModel, cmd )
