module Collection.View exposing (..)

import Collection.Types exposing (..)
import Configuration
import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import I18n
import Routes
import String
import Types exposing (..)
import Views exposing (viewCardThumbnail, viewLoading, viewWebData)
import WebData exposing (..)


view : Model -> I18n.Language -> Html Msg
view model language =
    viewWebData
        language
        (\loadingStatus ->
            case loadingStatus of
                Loading _ ->
                    div [ class "text-center" ]
                        [ viewLoading language ]

                Loaded body ->
                    let
                        collection =
                            case Dict.get body.data.id body.data.collections of
                                Nothing ->
                                    Debug.crash ("Collection not found id=" ++ body.data.id)

                                Just collection ->
                                    collection

                        user =
                            case Dict.get collection.authorId body.data.users of
                                Nothing ->
                                    Debug.crash ("User not found id=" ++ collection.authorId)

                                Just user ->
                                    user
                    in
                        div []
                            [ viewBanner language user collection
                            , viewCollectionContent language user collection body.data.cards body.data.values
                            ]
        )
        model.collection


viewBanner : I18n.Language -> User -> Collection -> Html Msg
viewBanner language user collection =
    div [ class "banner collection-header" ]
        [ div [ class "row full-bg" ]
            ((case collection.logo of
                Nothing ->
                    []

                Just logo ->
                    [ img [ class "cover", alt "screen", src (Configuration.apiUrlWithPath logo) ] []
                    ]
             )
                ++ [ div [ class "container" ]
                        [ div [ class "row" ]
                            [ div [ class "col-xs-8" ]
                                []
                            , -- [ ol [ class "breadcrumb" ]
                              --     [ li []
                              --         [ a [ href "#" ]
                              --             [ text "Home" ]
                              --         ]
                              --     , li []
                              --         [ a [ href "#" ]
                              --             [ text "Collection" ]
                              --         ]
                              --     , li [ class "active" ]
                              --         [ text "Outils de consultation" ]
                              --     ]
                              -- ]
                              div [ class "col-xs-4" ]
                                [ div [ class "pull-right banner-button" ]
                                    [ button
                                        [ class "btn btn-default btn-xs btn-action-negative"
                                        , attribute "data-target" "#edit-content"
                                        , attribute "data-toggle" "modal"
                                        , onClick (navigate ("/collections/" ++ collection.id ++ "/edit"))
                                        , type_ "button"
                                        ]
                                        [ text "Edit collection"
                                          -- TODO i18n
                                        ]
                                    ]
                                ]
                            ]
                        , div [ class "row " ]
                            [ div [ class "col-md-12 text-center" ]
                                [ div [ class "collection-info" ]
                                    [ -- TODO
                                      -- div [ class "collection-thumb" ]
                                      -- [ img [ alt "screen", src "img/france.png" ]
                                      --     []
                                      -- ]
                                      h4 []
                                        [ text "Collection"
                                          -- TODO i18n
                                        ]
                                    , h2 []
                                        [ text collection.name ]
                                    , h3 []
                                        [ text "Recommandé par "
                                          -- TODO i18n
                                        , span []
                                            [ text user.name ]
                                        ]
                                    ]
                                ]
                            ]
                        ]
                   ]
            )
        ]


viewCollectionContent : I18n.Language -> User -> Collection -> Dict String Card -> Dict String Value -> Html Msg
viewCollectionContent language user collection cards values =
    div [ class "row" ]
        [ div [ class "container" ]
            [ div
                [ class "row" ]
                [ div [ class "col-xs-12" ]
                    [ div [ class "panel panel-default panel-side" ]
                        [ h6 [ class "panel-title" ]
                            [ text (I18n.translate language I18n.Share) ]
                        , div [ class "panel-body chart" ]
                            -- [ button [ class "btn btn-default btn-action btn-round", type' "button" ]
                            --     [ i [ attribute "aria-hidden" "true", class "fa fa-facebook" ]
                            --         []
                            --     ]
                            [ a
                                [ class "btn btn-default btn-action btn-round twitter-share-button"
                                , href
                                    (let
                                        url =
                                            (String.dropRight 1 Configuration.appUrl)
                                                ++ (Routes.makeUrlWithLanguage
                                                        language
                                                        ("/collections/" ++ collection.id)
                                                   )

                                        -- TODO: i18n
                                     in
                                        ("https://twitter.com/intent/tweet?text="
                                            ++ Http.encodeUri
                                                (I18n.translate
                                                    language
                                                    (I18n.TweetMessage collection.name url)
                                                )
                                        )
                                    )
                                ]
                                [ i [ attribute "aria-hidden" "true", class "fa fa-twitter" ]
                                    []
                                ]
                              -- , button [ class "btn btn-default btn-action btn-round", type' "button" ]
                              --     [ i [ attribute "aria-hidden" "true", class "fa fa-google-plus" ]
                              --         []
                              --     ]
                              -- , button [ class "btn btn-default btn-action btn-round", type' "button" ]
                              --     [ i [ attribute "aria-hidden" "true", class "fa fa-linkedin" ]
                              --         []
                              --     ]
                            ]
                        ]
                    ]
                ]
            , div [ class "row" ]
                [ div [ class "col-md-12 content" ]
                    [ div [ class "row" ]
                        [ div [ class "col-xs-12" ]
                            [ div [ class "panel panel-default main" ]
                                [ div [ class "row" ]
                                    [ div [ class "col-xs-8 text-left" ]
                                        [ h3 [ class "panel-title" ]
                                            [ text "About"
                                              -- TODO i18n
                                            ]
                                        ]
                                    , div [ class "col-xs-4 text-right" ]
                                        []
                                    ]
                                , div [ class "panel-body simple" ]
                                    [ p []
                                        [ text collection.description ]
                                    ]
                                ]
                            , div [ class "panel panel-default" ]
                                [ div [ class "row" ]
                                    [ div [ class "col-xs-8 text-left" ]
                                        [ h4 [ class "zone-label" ]
                                            [ text "Outils"
                                              -- TODO i18n
                                            ]
                                        ]
                                      -- , div [ class "col-xs-4 text-right up7" ]
                                      --     [ a [ class "btn btn-default btn-xs btn-action", href "compare.html", type' "button" ]
                                      --         [ text "Compare"-- TODO i18n
                                      --          ]
                                      --     ]
                                    ]
                                , div [ class "panel-body" ]
                                    [ div [ class "row" ]
                                        (let
                                            toolCards =
                                                List.filterMap
                                                    (\cardId ->
                                                        let
                                                            card =
                                                                getCard cards cardId
                                                        in
                                                            if cardSubTypeIdsIntersect card.subTypeIds cardTypesForTool then
                                                                Just card
                                                            else
                                                                Nothing
                                                    )
                                                    collection.cardIds
                                         in
                                            List.map
                                                (viewCardThumbnail language navigate "tool grey" values)
                                                toolCards
                                        )
                                    ]
                                ]
                            ]
                        ]
                    ]
                ]
            ]
        , div [ class "row section grey last" ]
            [ div [ class "container" ]
                [ div [ class "col-xs-12" ]
                    [ h4 [ class "zone-label" ]
                        [ text "Utilisations"
                          -- TODO i18n
                        ]
                    , div [ class "row" ]
                        (let
                            useCaseCards =
                                List.filterMap
                                    (\cardId ->
                                        let
                                            card =
                                                getCard cards cardId
                                        in
                                            if
                                                List.any
                                                    (\subTypeId -> List.member subTypeId card.subTypeIds)
                                                    cardTypesForUseCase
                                            then
                                                Just card
                                            else
                                                Nothing
                                    )
                                    collection.cardIds
                         in
                            List.map
                                (viewCardThumbnail language navigate "example" values)
                                useCaseCards
                        )
                    ]
                ]
            ]
        ]
