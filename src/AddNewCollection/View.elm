module AddNewCollection.View exposing (..)

import AddNewCollection.Types exposing (..)
import Json.Decode as Decode
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Image.View exposing (..)
import I18n


view : Model -> I18n.Language -> Html Msg
view model language =
    let
        viewForm =
            div [ class "col-xs-12" ]
                [ div [ class "row section-form" ]
                    [ div [ class "col-xs-12" ]
                        [ div [ class "form-group" ]
                            [ label [ for "nameField" ]
                                [ text "Name" ]
                            , input
                                [ class "form-control"
                                , id "nameField"
                                , onInput (ForSelf << SetName)
                                , placeholder "What's the official name of the collection?"
                                  -- TODO i18n
                                , required True
                                , type_ "text"
                                , value model.fields.name
                                ]
                                []
                            ]
                        , div [ class "form-group" ]
                            [ label [ for "aboutField" ]
                                [ text "About" ]
                            , textarea
                                [ class "form-control"
                                , id "aboutField"
                                , onInput (ForSelf << SetDescription)
                                , value model.fields.description
                                ]
                                []
                            ]
                        , div [ class "form-group" ]
                            [ label [ for "cardIdsField" ]
                                [ text "Card URLs"
                                  -- TODO i18n
                                ]
                            , textarea
                                [ class "form-control"
                                , style [ ( "height", "30em" ) ]
                                , id "cardIdsField"
                                , onInput (ForSelf << SetCardIds)
                                , value model.fields.cardIds
                                ]
                                []
                            ]
                        ]
                    ]
                ]
    in
        Html.form
            [ onSubmit (ForSelf PostNewCollection) ]
            [ div [ class "row section" ]
                [ div [ class "container" ]
                    [ div [ class "row" ]
                        [ div [ class "col-md-12 content content-left" ]
                            [ div [ class "row" ]
                                [ div [ class "col-xs-12" ]
                                    [ h1 []
                                        -- [ text (I18n.translate language I18n.AddNewCollection) ]
                                        -- TODO i18n
                                        [ text
                                            (case model.editedCollectionId of
                                                Nothing ->
                                                    "Add Collection"

                                                Just _ ->
                                                    "Edit Collection"
                                            )
                                        ]
                                    ]
                                ]
                            ]
                        ]
                    , div [ class "row" ]
                        [ div [ class "col-md-9 content content-left" ]
                            [ div [ class "row" ]
                                [ viewForm ]
                            ]
                        , div [ class "col-md-3 sidebar" ]
                            [ div [ class "row" ]
                                [ div [ class "col-xs-12" ]
                                    [ div [ class "thumbnail orga grey" ]
                                        [ div [ class "upload-container" ]
                                            [ label [ for "logoField" ]
                                                [ text "Logo" ]
                                            , div [ class "upload-zone" ]
                                                [ viewImageUploadStatus language model.imageUploadStatus ]
                                            , input
                                                [ id "logoField"
                                                , on "change" (Decode.succeed (ForSelf ImageSelected))
                                                , type_ "file"
                                                ]
                                                []
                                            ]
                                        ]
                                    ]
                                ]
                              -- , div [ class "row" ]
                              --     [ div [ class "col-xs-12" ]
                              --         [ i []
                              --             [ text "Maecenas " ]
                              --         ]
                              --     ]
                            ]
                        ]
                    ]
                ]
            , div [ class "row section-form last" ]
                [ div [ class "container" ]
                    [ div [ class "col-md-9 content content-left" ]
                        [ button
                            [ class "btn btn-default pull-right"
                            , disabled (publishedDisabled model.imageUploadStatus)
                            , type_ "submit"
                            ]
                            [ text "Publish"
                              -- TODO i18n
                            ]
                        ]
                    ]
                ]
            ]
