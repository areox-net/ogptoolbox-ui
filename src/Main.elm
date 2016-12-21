module Main exposing (..)

import About
import AddNew.State
import AddNew.Types
import AddNew.View
import AddNewCollection.State
import AddNewCollection.Types
import AddNewCollection.View
import Authenticator.Activate
import Authenticator.Routes
import Authenticator.Types
import Authenticator.State
import Authenticator.View
import Card.State
import Card.Types
import Card.View
import Collection.State
import Collection.Types
import Collection.View
import Collections.State
import Collections.Types
import Collections.View
import Decoders
import Dict exposing (Dict)
import Dom.Scroll
import Erl
import Faq
import Home
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Attributes.Aria exposing (ariaHidden, ariaLabelledby)
import Html.Events exposing (onClick, onInput, onSubmit, onWithOptions)
import Html.Helpers exposing (aForPath)
import I18n
import Json.Decode
import Navigation
import Ports
import Routes exposing (..)
import Search.State
import Search.Types
import Search.View
import String
import Task
import Types exposing (..)
import Urls
import UserProfile.State
import UserProfile.Types
import UserProfile.View
import Views exposing (viewBigMessage, viewNotAuthentified, viewNotFound)


main : Program Flags Model Msg
main =
    Navigation.programWithFlags LocationChanged
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


type alias Flags =
    { language : String
    , authentication : Json.Decode.Value
    }



-- MODEL


type alias Model =
    { addNewModel : AddNew.Types.Model
    , addNewCollectionModel : AddNewCollection.Types.Model
    , activationModel : Authenticator.Activate.Model
    , authentication : Maybe Authenticator.Types.Authentication
    , authenticatorModel : Authenticator.Types.Model
    , authenticatorRoute : Maybe Authenticator.Routes.Route
    , cardModel : Card.Types.Model
    , collectionModel : Collection.Types.Model
    , collectionsModel : Collections.Types.Model
    , displayAddNewModal : Bool
    , location : Navigation.Location
    , navigatorLanguage : Maybe I18n.Language
    , route : Route
    , searchInputValue : String
    , searchModel : Search.Types.Model
    , signOutMsg : Maybe Msg
    , userProfileModel : UserProfile.Types.Model
    }


init : Flags -> Navigation.Location -> ( Model, Cmd Msg )
init flags location =
    { addNewModel = AddNew.State.init
    , addNewCollectionModel = AddNewCollection.State.init
    , activationModel = Authenticator.Activate.init
    , authentication =
        Json.Decode.decodeValue Decoders.userForPortDecoder flags.authentication
            |> Result.toMaybe
    , authenticatorModel = Authenticator.State.init
    , authenticatorRoute = Nothing
    , cardModel = Card.State.init
    , collectionModel = Collection.State.init
    , collectionsModel = Collections.State.init
    , displayAddNewModal = False
    , location = location
    , navigatorLanguage =
        flags.language
            |> String.left 2
            |> String.toLower
            |> I18n.languageFromIso639_1
    , route = I18nRouteWithoutLanguage ""
    , searchInputValue = ""
    , searchModel = Search.State.init
    , signOutMsg = Nothing
    , userProfileModel = UserProfile.State.init
    }
        |> update (LocationChanged location)



-- UPDATE


type Msg
    = Activate User
    | ActivationMsg Authenticator.Activate.InternalMsg
    | AddNewMsg AddNew.Types.InternalMsg
    | AddNewCollectionMsg AddNewCollection.Types.InternalMsg
    | AuthenticatorMsg Authenticator.Types.InternalMsg
    | CardMsg Card.Types.InternalMsg
    | ChangeAuthenticatorRoute (Maybe Authenticator.Routes.Route)
    | CloseAuthenticatorModalAndNavigate String
    | CollectionMsg Collection.Types.InternalMsg
    | CollectionsMsg Collections.Types.InternalMsg
    | DismissAuthenticatorModal
    | DisplayAddNewModal Bool
    | LocationChanged Navigation.Location
    | Navigate String
    | NavigateBack
    | NoOp
    | Search
    | SearchInputChanged String
    | SearchMsg Search.Types.InternalMsg
    | SignOutImmediately
    | StartAuthenticator (Maybe Msg) (Maybe Authenticator.Routes.Route)
    | UserProfileMsg UserProfile.Types.InternalMsg


navigateAfterSignOut : Model -> Cmd Msg
navigateAfterSignOut model =
    case model.signOutMsg of
        Just signOutMsg ->
            -- Execute sign out message to redirect to a new location.
            Task.perform (\_ -> signOutMsg) (Task.succeed ())

        Nothing ->
            -- Force page reload when sign out stays at the same location.
            Navigation.modifyUrl model.location.href


requireSignIn : Msg -> Model -> ( Model, Cmd Msg )
requireSignIn signOutMsg model =
    if model.authentication == Nothing then
        update (StartAuthenticator (Just NavigateBack) (Just Authenticator.Routes.SignInRoute)) model
    else
        ( { model | signOutMsg = Just signOutMsg }
        , Cmd.none
        )


translateActivationMsg : Authenticator.Activate.MsgTranslator Msg
translateActivationMsg =
    Authenticator.Activate.translateMsg
        { onInternalMsg = ActivationMsg
        , onActivate = Activate
        }


translateAddNewMsg : AddNew.Types.MsgTranslator Msg
translateAddNewMsg =
    AddNew.Types.translateMsg
        { onInternalMsg = AddNewMsg
        , onNavigate = Navigate
        }


translateAddNewCollectionMsg : AddNewCollection.Types.MsgTranslator Msg
translateAddNewCollectionMsg =
    AddNewCollection.Types.translateMsg
        { onInternalMsg = AddNewCollectionMsg
        , onNavigate = Navigate
        }


translateAuthenticatorMsg : Authenticator.Types.MsgTranslator Msg
translateAuthenticatorMsg =
    Authenticator.Types.translateMsg
        { onChangeRoute = ChangeAuthenticatorRoute
        , onInternalMsg = AuthenticatorMsg
        , onNavigate = CloseAuthenticatorModalAndNavigate
        }


translateCardMsg : Card.Types.MsgTranslator Msg
translateCardMsg =
    Card.Types.translateMsg
        { onInternalMsg = CardMsg
        , onNavigate = Navigate
        }


translateCollectionMsg : Collection.Types.MsgTranslator Msg
translateCollectionMsg =
    Collection.Types.translateMsg
        { onInternalMsg = CollectionMsg
        , onNavigate = Navigate
        }


translateCollectionsMsg : Collections.Types.MsgTranslator Msg
translateCollectionsMsg =
    Collections.Types.translateMsg
        { onInternalMsg = CollectionsMsg
        , onNavigate = Navigate
        }


translateSearchMsg : Search.Types.MsgTranslator Msg
translateSearchMsg =
    Search.Types.translateMsg
        { onInternalMsg = SearchMsg
        , onNavigate = Navigate
        }


translateUserProfileMsg : UserProfile.Types.MsgTranslator Msg
translateUserProfileMsg =
    UserProfile.Types.translateMsg
        { onInternalMsg = UserProfileMsg
        , onNavigate = Navigate
        }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        language =
            case model.route of
                I18nRouteWithLanguage language _ ->
                    language

                _ ->
                    I18n.English

        navigate urlPath =
            let
                currentUrlPath =
                    model.location.href
            in
                if currentUrlPath /= urlPath then
                    Navigation.newUrl urlPath
                else
                    Cmd.none
    in
        case msg of
            Activate authentication ->
                ( { model | authentication = Just authentication }
                , Cmd.none
                )

            ActivationMsg childMsg ->
                let
                    ( activationModel, childCmd ) =
                        Authenticator.Activate.update childMsg model.activationModel language
                in
                    ( { model | activationModel = activationModel }
                    , Cmd.map translateActivationMsg childCmd
                    )

            AddNewMsg childMsg ->
                let
                    ( addNewModel, childCmd ) =
                        AddNew.State.update childMsg model.addNewModel model.authentication language
                in
                    ( { model | addNewModel = addNewModel }
                    , Cmd.map translateAddNewMsg childCmd
                    )

            AddNewCollectionMsg childMsg ->
                let
                    ( addNewCollectionModel, childCmd ) =
                        AddNewCollection.State.update
                            childMsg
                            model.addNewCollectionModel
                            model.authentication
                            language
                in
                    ( { model | addNewCollectionModel = addNewCollectionModel }
                    , Cmd.map translateAddNewCollectionMsg childCmd
                    )

            AuthenticatorMsg childMsg ->
                let
                    ( authenticatorModel, childCmd ) =
                        Authenticator.State.update childMsg model.authenticatorModel

                    changed =
                        authenticatorModel.authentication /= model.authentication

                    model_ =
                        { model
                            | authentication = authenticatorModel.authentication
                            , authenticatorModel = authenticatorModel
                            , authenticatorRoute =
                                if changed then
                                    Nothing
                                else
                                    model.authenticatorRoute
                        }
                in
                    ( model_, Cmd.map translateAuthenticatorMsg childCmd )

            CardMsg childMsg ->
                let
                    ( cardModel, childCmd ) =
                        Card.State.update childMsg model.cardModel model.authentication language
                in
                    ( { model | cardModel = cardModel }
                    , Cmd.map translateCardMsg childCmd
                    )

            ChangeAuthenticatorRoute authenticatorRoute ->
                ( { model | authenticatorRoute = authenticatorRoute }
                , if authenticatorRoute == Nothing then
                    if model.authentication == Nothing then
                        navigateAfterSignOut model
                    else
                        -- Force page reload when authentication modal closes.
                        Navigation.modifyUrl model.location.href
                  else
                    Cmd.none
                )

            CloseAuthenticatorModalAndNavigate urlPath ->
                ( { model | authenticatorRoute = Nothing }
                , navigate urlPath
                )

            CollectionMsg childMsg ->
                let
                    ( collectionModel, childCmd ) =
                        Collection.State.update childMsg model.collectionModel model.authentication language
                in
                    ( { model | collectionModel = collectionModel }
                    , Cmd.map translateCollectionMsg childCmd
                    )

            CollectionsMsg childMsg ->
                let
                    ( collectionsModel, childCmd ) =
                        Collections.State.update childMsg model.collectionsModel model.authentication language
                in
                    ( { model | collectionsModel = collectionsModel }
                    , Cmd.map translateCollectionsMsg childCmd
                    )

            DismissAuthenticatorModal ->
                let
                    newModel =
                        { model | authenticatorRoute = Nothing }
                in
                    case model.signOutMsg of
                        Just signOutMsg ->
                            update signOutMsg newModel

                        Nothing ->
                            ( newModel, Cmd.none )

            DisplayAddNewModal displayAddNewModal ->
                ( { model | displayAddNewModal = displayAddNewModal }
                , Cmd.none
                )

            LocationChanged location ->
                urlUpdate location model

            Navigate urlPath ->
                let
                    cmd =
                        navigate urlPath
                in
                    ( model, cmd )

            NavigateBack ->
                ( model, Navigation.back 1 )

            NoOp ->
                ( model, Cmd.none )

            Search ->
                let
                    keptParams =
                        ( "q", model.searchInputValue )
                            :: (case getQuerySingleParameter "tagIds" model.location of
                                    Nothing ->
                                        []

                                    Just tagIds ->
                                        [ ( "tagIds", tagIds ) ]
                               )

                    urlPath =
                        "/tools?"
                            ++ (keptParams
                                    |> List.map (\( k, v ) -> k ++ "=" ++ v)
                                    |> String.join "&"
                               )

                    cmd =
                        navigate urlPath
                in
                    ( model, cmd )

            SearchInputChanged searchInputValue ->
                ( { model | searchInputValue = searchInputValue }, Cmd.none )

            SearchMsg childMsg ->
                let
                    ( newSearchModel, childCmd ) =
                        Search.State.update
                            childMsg
                            model.searchModel
                            model.authentication
                            language
                            model.location

                    newModel =
                        { model | searchModel = newSearchModel }
                in
                    ( newModel
                    , Cmd.map translateSearchMsg childCmd
                    )

            SignOutImmediately ->
                let
                    ( model1, cmd1 ) =
                        update (AuthenticatorMsg Authenticator.Types.signOutMsg) model
                in
                    model1 ! [ cmd1, navigateAfterSignOut model ]

            StartAuthenticator onCancel authenticatorRoute ->
                if model.authenticatorRoute == Nothing then
                    ( { model
                        | signOutMsg = onCancel
                        , authenticatorRoute = authenticatorRoute
                      }
                    , if authenticatorRoute == Nothing then
                        -- Force page reload when authenticator modal closes.
                        Navigation.modifyUrl <| model.location.href
                      else
                        Cmd.none
                    )
                else
                    -- Don't start a new authenticator session when one is pending.
                    ( model, Cmd.none )

            UserProfileMsg childMsg ->
                let
                    authentication =
                        case model.authentication of
                            Nothing ->
                                Debug.crash "prevented by viewNotAuthorized"

                            Just authentication ->
                                authentication

                    ( newUserProfileModel, childCmd ) =
                        UserProfile.State.update childMsg model.userProfileModel authentication language

                    newModel =
                        { model | userProfileModel = newUserProfileModel }
                in
                    ( newModel
                    , Cmd.map translateUserProfileMsg childCmd
                    )


urlUpdate : Navigation.Location -> Model -> ( Model, Cmd Msg )
urlUpdate location model =
    let
        searchQuery =
            getQuerySearchTerm location

        ( newModel, cmd ) =
            case parseLocation location of
                Just ((I18nRouteWithLanguage language localizedRoute) as route) ->
                    let
                        indexRoute titleSymbol descriptionSymbol =
                            let
                                getLocalizedString value =
                                    case value.value of
                                        LocalizedStringValue valueByLanguage ->
                                            case I18n.getValueByPreferredLanguage language valueByLanguage of
                                                Nothing ->
                                                    Debug.crash "indexRoute"

                                                Just tag ->
                                                    tag

                                        _ ->
                                            Debug.crash "indexRoute"

                                selectedTags =
                                    case getQuerySingleParameter "tagIds" location of
                                        Nothing ->
                                            []

                                        Just tagIds ->
                                            tagIds
                                                |> String.split ","
                                                |> List.map
                                                    (\tagId ->
                                                        { count = 50
                                                        , tag = ""
                                                        , tagId = tagId
                                                        }
                                                    )

                                searchModel =
                                    model.searchModel

                                newSearchModel =
                                    { searchModel | selectedTags = selectedTags }

                                ( newSearchModel2, searchCmd ) =
                                    Search.State.update
                                        Search.Types.Load
                                        newSearchModel
                                        model.authentication
                                        language
                                        location

                                newModel =
                                    { model
                                        | searchModel = newSearchModel2
                                        , searchInputValue = searchQuery
                                    }
                            in
                                newModel
                                    ! [ Cmd.map translateSearchMsg searchCmd
                                      , Ports.setDocumentMetadata
                                            { description = I18n.translate language descriptionSymbol
                                            , imageUrl = Urls.appLogoFullUrl
                                            , title = I18n.translate language titleSymbol
                                            }
                                      ]

                        ( localizedModel, localizedCmd ) =
                            case localizedRoute of
                                AboutRoute ->
                                    ( { model | signOutMsg = Nothing }
                                    , Ports.setDocumentMetadata
                                        { description = I18n.translate language I18n.AboutDescription
                                        , imageUrl = Urls.appLogoFullUrl
                                        , title = I18n.translate language I18n.About
                                        }
                                    )

                                ActivationRoute userId ->
                                    let
                                        ( activationModel, childCmd ) =
                                            Authenticator.Activate.update
                                                (Authenticator.Activate.ActivateUser
                                                    userId
                                                    (Routes.getQuerySingleParameter
                                                        "authorization"
                                                        location
                                                        |> Maybe.withDefault ""
                                                    )
                                                )
                                                model.activationModel
                                                language
                                    in
                                        ( { model
                                            | activationModel = activationModel
                                            , signOutMsg = Nothing
                                          }
                                        , Cmd.map translateActivationMsg childCmd
                                        )

                                CollectionsRoute childRoute ->
                                    case childRoute of
                                        CollectionRoute collectionId ->
                                            let
                                                ( collectionModel, childCmd ) =
                                                    Collection.State.update
                                                        (Collection.Types.LoadCollection collectionId)
                                                        model.collectionModel
                                                        model.authentication
                                                        language
                                            in
                                                ( { model
                                                    | collectionModel = collectionModel
                                                    , signOutMsg = Nothing
                                                  }
                                                , Cmd.map translateCollectionMsg childCmd
                                                )

                                        CollectionsIndexRoute ->
                                            let
                                                ( collectionsModel, childCmd ) =
                                                    Collections.State.update
                                                        Collections.Types.LoadCollections
                                                        model.collectionsModel
                                                        model.authentication
                                                        language
                                            in
                                                ( { model
                                                    | collectionsModel = collectionsModel
                                                    , signOutMsg = Nothing
                                                  }
                                                , Cmd.map translateCollectionsMsg childCmd
                                                )

                                        EditCollectionRoute collectionId ->
                                            let
                                                ( model1, cmd1 ) =
                                                    requireSignIn
                                                        (Navigate (Urls.parentUrl location.href))
                                                        model

                                                -- TODO: Only the owner of the collection and an admin can edit it.
                                                ( addNewCollectionModel, childCmd ) =
                                                    AddNewCollection.State.update
                                                        (AddNewCollection.Types.LoadCollection collectionId)
                                                        model1.addNewCollectionModel
                                                        model1.authentication
                                                        language
                                            in
                                                { model1
                                                    | addNewCollectionModel = addNewCollectionModel
                                                }
                                                    ! [ cmd1
                                                      , Cmd.map translateAddNewCollectionMsg childCmd
                                                      ]

                                        NewCollectionRoute ->
                                            requireSignIn (Navigate (Urls.parentUrl location.href)) model

                                FaqRoute ->
                                    ( model
                                    , Ports.setDocumentMetadata
                                        { description = I18n.translate language I18n.FaqDescription
                                        , imageUrl = Urls.appLogoFullUrl
                                        , title = I18n.translate language I18n.Faq
                                        }
                                    )

                                HomeRoute ->
                                    indexRoute I18n.HomeTitle I18n.HomeDescription

                                NotFoundRoute _ ->
                                    ( model
                                    , Ports.setDocumentMetadata
                                        { description = I18n.translate language I18n.PageNotFoundDescription
                                        , imageUrl = Urls.appLogoFullUrl
                                        , title = I18n.translate language I18n.PageNotFound
                                        }
                                    )

                                OrganizationsRoute childRoute ->
                                    case childRoute of
                                        OrganizationRoute cardId ->
                                            let
                                                ( cardModel, childCmd ) =
                                                    Card.State.update
                                                        (Card.Types.LoadCard cardId)
                                                        model.cardModel
                                                        model.authentication
                                                        language

                                                newModel =
                                                    { model | cardModel = cardModel }
                                            in
                                                ( model, Cmd.map translateCardMsg childCmd )

                                        OrganizationsIndexRoute ->
                                            indexRoute (I18n.Organization I18n.Plural) I18n.OrganizationsDescription

                                        NewOrganizationRoute ->
                                            let
                                                ( model1, cmd1 ) =
                                                    requireSignIn
                                                        (Navigate (Urls.parentUrl location.href))
                                                        model

                                                addNewModel =
                                                    model1.addNewModel

                                                newAddNewModel =
                                                    { addNewModel
                                                        | fields = Dict.fromList [ ( "Types", "organization" ) ]
                                                    }
                                            in
                                                { model1 | addNewModel = newAddNewModel }
                                                    ! [ cmd1
                                                      , Ports.setDocumentMetadata
                                                            { description =
                                                                I18n.translate
                                                                    language
                                                                    I18n.AddNewOrganizationDescription
                                                            , imageUrl = Urls.appLogoFullUrl
                                                            , title = I18n.translate language I18n.AddNewOrganization
                                                            }
                                                      ]

                                ToolsRoute childRoute ->
                                    case childRoute of
                                        ToolRoute cardId ->
                                            let
                                                ( cardModel, childCmd ) =
                                                    Card.State.update
                                                        (Card.Types.LoadCard cardId)
                                                        model.cardModel
                                                        model.authentication
                                                        language

                                                newModel =
                                                    { model | cardModel = cardModel }
                                            in
                                                ( model, Cmd.map translateCardMsg childCmd )

                                        ToolsIndexRoute ->
                                            indexRoute (I18n.Tool I18n.Plural) I18n.ToolsDescription

                                        NewToolRoute ->
                                            let
                                                ( model1, cmd1 ) =
                                                    requireSignIn
                                                        (Navigate (Urls.parentUrl location.href))
                                                        model

                                                addNewModel =
                                                    model1.addNewModel

                                                newAddNewModel =
                                                    { addNewModel
                                                        | fields = Dict.fromList [ ( "Types", "software" ) ]
                                                    }
                                            in
                                                { model1 | addNewModel = newAddNewModel }
                                                    ! [ cmd1
                                                      , Ports.setDocumentMetadata
                                                            { description =
                                                                I18n.translate language I18n.AddNewToolDescription
                                                            , imageUrl = Urls.appLogoFullUrl
                                                            , title = I18n.translate language I18n.AddNewTool
                                                            }
                                                      ]

                                UseCasesRoute childRoute ->
                                    case childRoute of
                                        UseCaseRoute cardId ->
                                            let
                                                ( cardModel, childCmd ) =
                                                    Card.State.update
                                                        (Card.Types.LoadCard cardId)
                                                        model.cardModel
                                                        model.authentication
                                                        language

                                                newModel =
                                                    { model | cardModel = cardModel }
                                            in
                                                ( model, Cmd.map translateCardMsg childCmd )

                                        UseCasesIndexRoute ->
                                            indexRoute (I18n.UseCase I18n.Plural) I18n.UseCasesDescription

                                        NewUseCaseRoute ->
                                            let
                                                ( model1, cmd1 ) =
                                                    requireSignIn
                                                        (Navigate (Urls.parentUrl location.href))
                                                        model

                                                addNewModel =
                                                    model1.addNewModel

                                                newAddNewModel =
                                                    { addNewModel
                                                        | fields = Dict.fromList [ ( "Types", "use-case" ) ]
                                                    }
                                            in
                                                { model1 | addNewModel = newAddNewModel }
                                                    ! [ cmd1
                                                      , Ports.setDocumentMetadata
                                                            { description =
                                                                I18n.translate language I18n.AddNewUseCaseDescription
                                                            , title = I18n.translate language I18n.AddNewUseCase
                                                            , imageUrl = Urls.appLogoFullUrl
                                                            }
                                                      ]

                                UserProfileRoute ->
                                    let
                                        ( model1, cmd1 ) =
                                            requireSignIn
                                                -- Logout => Home
                                                (Navigate (Urls.absoluteUrlPathWithLanguage language "/"))
                                                model

                                        -- TODO: Everybody can see the collections, but he can't see everything nor edit
                                        -- it.
                                        authentication =
                                            case model1.authentication of
                                                Nothing ->
                                                    Debug.crash "prevented by viewNotAuthorized"

                                                Just authentication ->
                                                    authentication

                                        ( userProfileModel, childCmd ) =
                                            UserProfile.State.update
                                                (UserProfile.Types.LoadCollections authentication.urlName)
                                                model1.userProfileModel
                                                authentication
                                                language
                                    in
                                        { model1 | userProfileModel = userProfileModel }
                                            ! [ cmd1
                                              , Cmd.map translateUserProfileMsg childCmd
                                              ]
                    in
                        ( { localizedModel | route = route }, localizedCmd )

                Just ((I18nRouteWithoutLanguage urlPath) as route) ->
                    let
                        language =
                            model.navigatorLanguage |> Maybe.withDefault I18n.English

                        command =
                            Urls.absoluteUrlPathWithLanguage language
                                (urlPath ++ (queryStringForParams [ "q", "tagIds" ] location))
                                |> Navigation.modifyUrl
                    in
                        ( { model | route = route }, command )

                Nothing ->
                    let
                        language =
                            model.navigatorLanguage |> Maybe.withDefault I18n.English

                        url =
                            location.href
                                |> Erl.parse

                        newUrl =
                            { url | path = (I18n.iso639_1FromLanguage language) :: url.path }
                    in
                        ( model, Navigation.modifyUrl (Erl.toString newUrl) )
    in
        { newModel | location = location }
            ! [ Task.attempt
                    (\result ->
                        case result of
                            Result.Err _ ->
                                Debug.crash "Dom.Scroll.toTop \"html-element\""

                            Result.Ok _ ->
                                NoOp
                    )
                    (Dom.Scroll.toTop "html-element")
              , cmd
              ]



-- VIEW


view : Model -> Html Msg
view model =
    let
        standardLayout language content =
            div []
                ([ viewHeader model language "container"
                 , viewAlert model language
                 ]
                    ++ [ content
                       , viewFooter model language
                       , viewAuthenticatorModal model language
                       , viewAddNewModal model language
                       , viewBackdrop model
                       ]
                )

        fullscreenLayout language content =
            div [ class "main-container" ]
                ([ div [ class "fixed-header" ]
                    [ viewHeader model language "container-fluid"
                    , viewAlert model language
                    ]
                 ]
                    ++ [ content
                       , div [ class "fixed-footer" ]
                            [ text (I18n.translate language I18n.Copyright) ]
                       , viewAuthenticatorModal model language
                       , viewAddNewModal model language
                       , viewBackdrop model
                       ]
                )

        searchQuery =
            getQuerySearchTerm model.location
    in
        case model.route of
            I18nRouteWithLanguage language route ->
                case route of
                    AboutRoute ->
                        About.view language
                            |> standardLayout language

                    ActivationRoute userId ->
                        Authenticator.Activate.view model.activationModel language userId
                            |> Html.map translateActivationMsg
                            |> standardLayout language

                    CollectionsRoute childRoute ->
                        case childRoute of
                            CollectionRoute _ ->
                                Collection.View.view model.collectionModel language
                                    |> Html.map translateCollectionMsg
                                    |> standardLayout language

                            CollectionsIndexRoute ->
                                Collections.View.view model.collectionsModel language
                                    |> Html.map translateCollectionsMsg
                                    |> standardLayout language

                            EditCollectionRoute _ ->
                                AddNewCollection.View.view model.addNewCollectionModel language
                                    |> Html.map translateAddNewCollectionMsg
                                    |> standardLayout language

                            NewCollectionRoute ->
                                AddNewCollection.View.view model.addNewCollectionModel language
                                    |> Html.map translateAddNewCollectionMsg
                                    |> standardLayout language

                    FaqRoute ->
                        Faq.view language
                            |> standardLayout language

                    HomeRoute ->
                        Home.view model.searchModel language model.location
                            |> Html.map translateSearchMsg
                            |> standardLayout language

                    NotFoundRoute _ ->
                        div [ class "row section" ]
                            [ div [ class "container" ]
                                [ viewNotFound language ]
                            ]
                            |> standardLayout language

                    OrganizationsRoute childRoute ->
                        case childRoute of
                            OrganizationRoute _ ->
                                Card.View.view model.cardModel language
                                    |> Html.map translateCardMsg
                                    |> standardLayout language

                            OrganizationsIndexRoute ->
                                Search.View.view model.searchModel OrganizationCard language model.location
                                    |> Html.map translateSearchMsg
                                    |> fullscreenLayout language

                            NewOrganizationRoute ->
                                AddNew.View.viewOrganization model.addNewModel language
                                    |> Html.map translateAddNewMsg
                                    |> standardLayout language

                    ToolsRoute childRoute ->
                        case childRoute of
                            ToolRoute _ ->
                                Card.View.view model.cardModel language
                                    |> Html.map translateCardMsg
                                    |> standardLayout language

                            ToolsIndexRoute ->
                                Search.View.view model.searchModel ToolCard language model.location
                                    |> Html.map translateSearchMsg
                                    |> fullscreenLayout language

                            NewToolRoute ->
                                AddNew.View.viewTool model.addNewModel language
                                    |> Html.map translateAddNewMsg
                                    |> standardLayout language

                    UseCasesRoute childRoute ->
                        case childRoute of
                            UseCaseRoute _ ->
                                Card.View.view model.cardModel language
                                    |> Html.map translateCardMsg
                                    |> standardLayout language

                            UseCasesIndexRoute ->
                                Search.View.view model.searchModel UseCaseCard language model.location
                                    |> Html.map translateSearchMsg
                                    |> fullscreenLayout language

                            NewUseCaseRoute ->
                                AddNew.View.viewUseCase model.addNewModel language
                                    |> Html.map translateAddNewMsg
                                    |> standardLayout language

                    UserProfileRoute ->
                        (case model.authentication of
                            Nothing ->
                                viewNotAuthentified language

                            Just user ->
                                UserProfile.View.view model.userProfileModel language user
                                    |> Html.map translateUserProfileMsg
                        )
                            |> standardLayout language

            I18nRouteWithoutLanguage _ ->
                div [ style [ ( "min-height", "60em" ) ] ]
                    [ viewBigMessage "" "" ]
                    |> standardLayout I18n.English


viewAddNewModal : Model -> I18n.Language -> Html Msg
viewAddNewModal model language =
    if model.displayAddNewModal then
        div
            [ ariaLabelledby "myModalLabel"
            , attribute "role" "dialog"
            , attribute "tabindex" "-1"
            , class "modal fade in"
            , style [ ( "display", "block" ) ]
            ]
            [ div [ class "modal-dialog", id "login-overlay" ]
                [ div [ class "modal-content" ]
                    [ div [ class "modal-header" ]
                        [ button
                            [ class "close"
                            , attribute "data-dismiss" "modal"
                            , onClick (DisplayAddNewModal False)
                            , type_ "button"
                            ]
                            [ span [ attribute "aria-hidden" "true" ]
                                [ text "×" ]
                            , span [ class "sr-only" ]
                                [ text "Close" ]
                            ]
                        , h4 [ class "modal-title", id "myModalLabel" ]
                            [ text (I18n.translate language (I18n.AddNewItemBox)) ]
                        ]
                    , div [ class "modal-body" ]
                        [ div [ class "row" ]
                            [ div [ class "col-xs-12" ]
                                [ aForPath
                                    Navigate
                                    language
                                    "/tools/new"
                                    [ class "media action"
                                      -- TODO trigger a login if not signed in
                                    , onClick (DisplayAddNewModal False)
                                    ]
                                    [ div [ class "media-left icon" ]
                                        [ span [ attribute "aria-hidden" "true", class "glyphicon glyphicon-wrench" ]
                                            []
                                        ]
                                    , div [ class "media-body" ]
                                        [ h4 [ class "media-heading" ]
                                            [ text (I18n.translate language (I18n.Tool I18n.Singular)) ]
                                        , text (I18n.translate language I18n.AddNewToolCatchPhrase)
                                        ]
                                    ]
                                , aForPath
                                    Navigate
                                    language
                                    "/use-cases/new"
                                    [ class "media action"
                                      -- TODO trigger a login if not signed in
                                    , onClick (DisplayAddNewModal False)
                                    ]
                                    [ div [ class "media-left icon" ]
                                        [ span [ attribute "aria-hidden" "true", class "glyphicon glyphicon-bookmark" ]
                                            []
                                        ]
                                    , div [ class "media-body" ]
                                        [ h4 [ class "media-heading" ]
                                            [ text (I18n.translate language (I18n.UseCase I18n.Singular)) ]
                                        , text (I18n.translate language I18n.AddNewUseCaseCatchPhrase)
                                        ]
                                    ]
                                , aForPath
                                    Navigate
                                    language
                                    "/collections/new"
                                    [ class "media action"
                                      -- TODO trigger a login if not signed in
                                    , onClick (DisplayAddNewModal False)
                                    ]
                                    [ div [ class "media-left icon" ]
                                        [ span [ attribute "aria-hidden" "true", class "glyphicon glyphicon-heart" ]
                                            []
                                        ]
                                    , div [ class "media-body" ]
                                        [ h4 [ class "media-heading" ]
                                            [ text (I18n.translate language (I18n.Collection I18n.Singular)) ]
                                        , text (I18n.translate language I18n.AddNewCollectionCatchPhrase)
                                        ]
                                    ]
                                ]
                            ]
                        ]
                    ]
                ]
            ]
    else
        text ""


viewAlert : Model -> I18n.Language -> Html Msg
viewAlert model language =
    case model.authentication of
        Nothing ->
            text ""

        Just authentication ->
            if authentication.activated then
                text ""
            else
                div [ class "alert alert-success alert-dismissible", attribute "role" "alert" ]
                    [ div [ class "container" ]
                        -- [ button [ attribute "aria-label" "Close", class "close", attribute "data-dismiss" "alert", type_ "button" ]
                        --     [ span [ attribute "aria-hidden" "true" ]
                        --         [ text "×" ]
                        --     ]
                        [ text (I18n.translate language (I18n.EmailSentForAccountActivation authentication.email))
                        , text " "
                        , button
                            [ class "btn btn-default btn-sm"
                            , type_ "button"
                            , onWithOptions
                                "click"
                                { preventDefault = True, stopPropagation = False }
                                (Json.Decode.succeed
                                    (ActivationMsg (Authenticator.Activate.SendActivation authentication))
                                )
                            ]
                            [ text <| I18n.translate language I18n.SendEmailAgain ]
                        ]
                    ]


viewAuthenticatorModal : Model -> I18n.Language -> Html Msg
viewAuthenticatorModal model language =
    case model.authenticatorRoute of
        Just authenticatorRoute ->
            div
                [ ariaLabelledby "modal-title"
                , attribute "role" "dialog"
                , attribute "tabindex" "-1"
                , class "modal fade in"
                , style [ ( "display", "block" ) ]
                ]
                [ div [ class "modal-dialog", id "login-overlay" ]
                    [ div [ class "modal-content" ]
                        [ div [ class "modal-header" ]
                            [ button
                                [ attribute "data-dismiss" "modal"
                                , class "close"
                                , onWithOptions
                                    "click"
                                    { preventDefault = True, stopPropagation = False }
                                    (Json.Decode.succeed DismissAuthenticatorModal)
                                , type_ "button"
                                ]
                                [ span [ ariaHidden True ]
                                    [ text "×" ]
                                , span [ class "sr-only" ]
                                    [ text (I18n.translate language I18n.Close) ]
                                ]
                            , h4 [ class "modal-title", id "modal-title" ]
                                [ text (Authenticator.View.modalTitle language authenticatorRoute) ]
                            ]
                        , Authenticator.View.viewModalBody language authenticatorRoute model.authenticatorModel
                            |> Html.map translateAuthenticatorMsg
                        ]
                    ]
                ]

        Nothing ->
            text ""


viewBackdrop : Model -> Html Msg
viewBackdrop model =
    div [ classList [ ( "modal-backdrop in", model.authenticatorRoute /= Nothing || model.displayAddNewModal ) ] ]
        []


viewFooter : Model -> I18n.Language -> Html Msg
viewFooter model language =
    footer []
        [ div [ class "row section footer" ]
            [ div [ class "container" ]
                [ div [ class "row" ]
                    [ div [ class "col-xs-12 col-md-6" ]
                        [ div [ class "row" ]
                            [ div [ class "col-xs-6" ]
                                [ img [ alt "OGP logo", class "footer-logo", src "/img/ogp-logo.png" ]
                                    []
                                ]
                            , div [ class "col-xs-6" ]
                                [ h4 []
                                    [ text (I18n.translate language I18n.LanguageWord) ]
                                , div [ class "dropdown dropdown-language" ]
                                    [ button
                                        [ attribute "aria-expanded" "true"
                                        , attribute "aria-haspopup" "true"
                                        , class "btn btn-default dropdown-toggle"
                                        , attribute "data-toggle" "dropdown"
                                        , id "dropdownMenu1"
                                        , type_ "button"
                                        ]
                                        [ text (I18n.translate language (I18n.Language language))
                                        , span [ class "caret" ] []
                                        ]
                                    , ul [ attribute "aria-labelledby" "dropdownMenu1", class "dropdown-menu" ]
                                        (let
                                            aForPath urlPath children =
                                                a
                                                    [ href urlPath
                                                    , onWithOptions
                                                        "click"
                                                        { stopPropagation = True, preventDefault = True }
                                                        (Json.Decode.succeed (Navigate urlPath))
                                                    ]
                                                    children
                                         in
                                            [ li []
                                                [ aForPath
                                                    (replaceLanguageInLocation I18n.English model.location)
                                                    [ text (I18n.translate I18n.English (I18n.Language I18n.English)) ]
                                                ]
                                            , li []
                                                [ aForPath
                                                    (replaceLanguageInLocation I18n.French model.location)
                                                    [ text (I18n.translate I18n.French (I18n.Language I18n.French)) ]
                                                ]
                                            , li []
                                                [ aForPath
                                                    (replaceLanguageInLocation I18n.Spanish model.location)
                                                    [ text (I18n.translate I18n.Spanish (I18n.Language I18n.Spanish)) ]
                                                ]
                                            ]
                                        )
                                    ]
                                ]
                            ]
                        , p [ class "info-box" ]
                            [ text (I18n.translate language I18n.OpenGovParagraph) ]
                        , a [ href "https://www.etalab.gouv.fr", target "_blank", class "etalab-logo" ]
                            [ img [ alt "Etalab logo", src "/img/etalab-logo.png" ]
                                []
                            ]
                        ]
                    , div [ class "col-xs-6 col-md-3" ]
                        [ h4 []
                            [ text (I18n.translate language I18n.FooterDiscover) ]
                        , ul [ class "footer-menu" ]
                            [ li []
                                [ aForPath
                                    Navigate
                                    language
                                    "/tools"
                                    []
                                    [ text (I18n.translate language (I18n.Tool I18n.Plural)) ]
                                ]
                            , li []
                                [ aForPath
                                    Navigate
                                    language
                                    "/use-cases"
                                    []
                                    [ text (I18n.translate language (I18n.UseCase I18n.Plural)) ]
                                ]
                            , li []
                                [ aForPath
                                    Navigate
                                    language
                                    "/organizations"
                                    []
                                    [ text (I18n.translate language (I18n.Organization I18n.Plural)) ]
                                ]
                            , li []
                                [ aForPath
                                    Navigate
                                    language
                                    "/collections"
                                    []
                                    [ text (I18n.translate language (I18n.Collection I18n.Plural)) ]
                                ]
                            ]
                        ]
                    , div [ class "col-xs-6 col-md-3" ]
                        [ h4 []
                            [ text (I18n.translate language I18n.FooterAbout) ]
                        , ul [ class "footer-menu" ]
                            [ li []
                                [ aForPath
                                    Navigate
                                    language
                                    "/about"
                                    []
                                    [ text (I18n.translate language I18n.About) ]
                                ]
                            , li []
                                [ aForPath
                                    Navigate
                                    language
                                    "/faq"
                                    []
                                    [ text (I18n.translate language I18n.Faq) ]
                                ]
                            , li []
                                [ a [ href "http://www.opengovpartnership.org", target "_blank" ]
                                    [ text "Open Government Parntenrship" ]
                                ]
                            , li []
                                [ a [ href "https://www.etalab.gouv.fr", target "_blank" ]
                                    [ text "Etalab" ]
                                ]
                            ]
                        ]
                    ]
                , div [ class "row copyright" ]
                    [ div [ class "col-md-12" ]
                        [ text (I18n.translate language I18n.Copyright) ]
                    ]
                ]
            ]
        ]


viewHeader : Model -> I18n.Language -> String -> Html Msg
viewHeader model language containerClass =
    let
        profileNavItem =
            case model.authentication of
                Just authentication ->
                    li []
                        [ aForPath
                            Navigate
                            language
                            "/profile"
                            []
                            [ text authentication.name ]
                        ]

                Nothing ->
                    text ""

        -- li []
        --     [ a
        --         [ href "#"
        --         , onWithOptions
        --             "click"
        --             { preventDefault = True, stopPropagation = False }
        --             (Json.Decode.succeed
        --                 (StartAuthenticator Nothing (Just Authenticator.Routes.ResetPasswordRoute))
        --             )
        --         ]
        --         [ text (I18n.translate language I18n.ResetPassword) ]
        --     ]
        signInOrOutNavItem =
            case model.authentication of
                Just authentication ->
                    li []
                        [ a
                            [ href "#"
                            , onWithOptions
                                "click"
                                { preventDefault = True, stopPropagation = False }
                                (Json.Decode.succeed SignOutImmediately)
                            ]
                            [ text (I18n.translate language I18n.SignOut) ]
                        ]

                Nothing ->
                    li []
                        [ a
                            [ href "#"
                            , onWithOptions
                                "click"
                                { preventDefault = True, stopPropagation = False }
                                (Json.Decode.succeed
                                    (StartAuthenticator Nothing (Just Authenticator.Routes.SignInRoute))
                                )
                            ]
                            [ text (I18n.translate language I18n.SignIn) ]
                        ]
    in
        header []
            [ nav [ class "navbar navbar-default navbar-fixed-top", attribute "role" "navigation" ]
                [ div [ class containerClass ]
                    [ div [ class "navbar-header" ]
                        [ button
                            [ attribute "aria-controls" "navbar"
                            , attribute "aria-expanded" "false"
                            , class "navbar-toggle collapsed"
                            , attribute "data-target" "#menu-collapse"
                            , attribute "data-toggle" "collapse"
                            , type_ "button"
                            ]
                            [ span [ class "sr-only" ]
                                [ text "Toggle navigation" ]
                            , span [ class "icon-bar" ]
                                []
                            , span [ class "icon-bar" ]
                                []
                            , span [ class "icon-bar" ]
                                []
                            ]
                        , aForPath
                            Navigate
                            language
                            "/"
                            [ class "navbar-brand" ]
                            [ text "OGPtoolbox" ]
                        , p [ class "navbar-text" ]
                            [ text (I18n.translate language I18n.HeaderTitle) ]
                        ]
                    , ul [ class "nav navbar-nav navbar-right collapse navbar-collapse" ]
                        [ profileNavItem
                        , signInOrOutNavItem
                        , li []
                            [ button
                                [ class "btn btn-default btn-action"
                                , onClick (DisplayAddNewModal True)
                                , type_ "button"
                                ]
                                [ text (I18n.translate language I18n.AddNew) ]
                            ]
                        ]
                    ]
                ]
            , nav [ class "navbar navbar-inverse" ]
                [ div [ class containerClass ]
                    [ Html.form
                        [ class "navbar-form navbar-right collapse mobile"
                        , onSubmit Search
                        ]
                        [ div [ class "form-group search-bar" ]
                            [ span [ attribute "aria-hidden" "true", class "glyphicon glyphicon-search" ]
                                []
                            , input
                                [ class "form-control"
                                , onInput SearchInputChanged
                                , placeholder (I18n.translate language I18n.SearchInputPlaceholder)
                                , type_ "search"
                                , value model.searchInputValue
                                ]
                                []
                            ]
                        ]
                    , div [ class "collapse navbar-collapse" ]
                        [ ul [ class "nav navbar-nav" ]
                            [ li []
                                [ aForPath
                                    Navigate
                                    language
                                    "/tools"
                                    []
                                    [ text (I18n.translate language (I18n.Tool I18n.Plural)) ]
                                ]
                            , li []
                                [ aForPath
                                    Navigate
                                    language
                                    "/use-cases"
                                    []
                                    [ text (I18n.translate language (I18n.UseCase I18n.Plural)) ]
                                ]
                              --   , li []
                              --       [ aForPath
                              --           Navigate
                              --           language
                              --           "/organizations"
                              --           []
                              --           [ text (I18n.translate language (I18n.Organization I18n.Plural)) ]
                              --       ]
                            , li []
                                [ aForPath
                                    Navigate
                                    language
                                    "/collections"
                                    []
                                    [ text (I18n.translate language (I18n.Collection I18n.Plural)) ]
                                ]
                            , li []
                                [ aForPath
                                    Navigate
                                    language
                                    "/faq"
                                    []
                                    [ text (I18n.translate language I18n.Help) ]
                                ]
                            ]
                        , Html.form
                            [ class "navbar-form navbar-right"
                            , onSubmit Search
                            ]
                            [ div [ class "form-group search-bar" ]
                                [ span [ attribute "aria-hidden" "true", class "glyphicon glyphicon-search" ]
                                    []
                                , input
                                    [ class "form-control"
                                    , onInput SearchInputChanged
                                    , placeholder (I18n.translate language I18n.SearchInputPlaceholder)
                                    , type_ "search"
                                    , value model.searchInputValue
                                    ]
                                    []
                                ]
                            ]
                        ]
                    , div [ class "collapse", id "menu-collapse" ]
                        [ ul [ class "nav navbar-nav navbar-inverse" ]
                            [ button
                                [ class "btn btn-default btn-action"
                                , onClick (DisplayAddNewModal True)
                                , type_ "button"
                                ]
                                [ text (I18n.translate language I18n.AddNew) ]
                            , li []
                                [ aForPath
                                    Navigate
                                    language
                                    "/tools"
                                    []
                                    [ text (I18n.translate language (I18n.Tool I18n.Plural)) ]
                                ]
                            , li []
                                [ aForPath
                                    Navigate
                                    language
                                    "/use-cases"
                                    []
                                    [ text (I18n.translate language (I18n.UseCase I18n.Plural)) ]
                                ]
                              --   , li []
                              --       [ aForPath
                              --           Navigate
                              --           language
                              --           "/organizations"
                              --           []
                              --           [ text (I18n.translate language (I18n.Organization I18n.Plural)) ]
                              --       ]
                            , li []
                                [ aForPath
                                    Navigate
                                    language
                                    "/collections"
                                    []
                                    [ text (I18n.translate language (I18n.Collection I18n.Plural)) ]
                                ]
                            , li []
                                [ aForPath
                                    Navigate
                                    language
                                    "/faq"
                                    []
                                    [ text (I18n.translate language I18n.Help) ]
                                ]
                            , profileNavItem
                            , signInOrOutNavItem
                            ]
                        ]
                    ]
                ]
            ]



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    -- TODO Fix duplicate messages with port "fileContentRead", that was worked around by a "Selected" constructor.
    Sub.batch
        [ Sub.map AddNewMsg (AddNew.State.subscriptions model.addNewModel)
        , Sub.map AddNewCollectionMsg (AddNewCollection.State.subscriptions model.addNewCollectionModel)
        , Sub.map SearchMsg (Search.State.subscriptions model.searchModel)
        ]
