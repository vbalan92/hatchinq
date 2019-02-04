module Hatchinq.List exposing (Config, Message, State, View, configure, imageSrc, init, itemsCount, secondaryText, update)

{-|


# Exposed

@docs Config, Message, State, View, configure, imageSrc, init, itemsCount, secondaryText, update

-}

import Element exposing (Element, centerY, fill, height, html, htmlAttribute, inFront, mouseOver, paddingEach, paddingXY, px, scrollbarY, width)
import Element.Background as Background
import Element.Border as Border
import Element.Events as Events
import Element.Font as Font
import Hatchinq.Attribute exposing (Attribute, custom, toElement, toInternalView)
import Hatchinq.Theme exposing (Theme, textWithEllipsis)
import Html
import Html.Attributes
import Task



-- TYPES


{-| -}
type alias State item =
    { id : Maybe String
    , selected : Maybe item
    }


{-| -}
init : State item
init =
    State Nothing Nothing



-- MESSAGES


{-| -}
type Message item msg
    = Select (Maybe item) (Maybe msg)



-- UPDATE


{-| -}
update : Message item msg -> State item -> ( State item, Cmd msg )
update message state =
    case message of
        Select item onSelect ->
            ( { state | selected = item }
            , case onSelect of
                Just msg ->
                    Task.succeed msg |> Task.perform identity

                Nothing ->
                    Cmd.none
            )



-- CONFIG


{-| -}
type alias Config item msg =
    { theme : Theme
    , lift : Message item msg -> msg
    }


{-| -}
configure : Config item msg -> (List (Attribute (InternalConfig item)) -> View item msg -> Element msg)
configure config =
    view config


type alias InternalConfig item =
    { toSecondaryText : Maybe (item -> String)
    , toImageSrc : Maybe (item -> String)
    , itemsCount : Maybe Int
    }


{-| -}
secondaryText : (item -> String) -> Attribute (InternalConfig item)
secondaryText toSecondaryText =
    custom (\v -> { v | toSecondaryText = Just toSecondaryText })


{-| -}
imageSrc : (item -> String) -> Attribute (InternalConfig item)
imageSrc toImageSrc =
    custom (\v -> { v | toImageSrc = Just toImageSrc })


{-| -}
itemsCount : Int -> Attribute (InternalConfig item)
itemsCount n =
    custom (\v -> { v | itemsCount = Just n })



-- VIEW


{-| -}
type alias View item msg =
    { items : List item
    , toPrimaryText : item -> String
    , onSelect : Maybe (item -> msg)
    , activated : Maybe item
    , state : State item
    }


view : Config item msg -> List (Attribute (InternalConfig item)) -> View item msg -> Element msg
view config attributes data =
    let
        { theme, lift } =
            config

        defaultInternalConfig =
            { toSecondaryText = Nothing
            , toImageSrc = Nothing
            , itemsCount = Nothing
            }

        internalConfig =
            defaultInternalConfig |> toInternalView attributes

        externalAttributes =
            toElement attributes

        bodyAttributes =
            [ paddingXY 0 8
            , width (px 280)
            ]

        extraAttributes =
            case data.onSelect of
                Nothing ->
                    [ htmlAttribute (Html.Attributes.tabindex -1)
                    , Events.onLoseFocus (lift <| Select Nothing Nothing)
                    ]

                _ ->
                    []

        itemHeightPx =
            case internalConfig.toImageSrc of
                Just toImageSrc ->
                    case internalConfig.toSecondaryText of
                        Just _ ->
                            72

                        Nothing ->
                            56

                Nothing ->
                    case internalConfig.toSecondaryText of
                        Just _ ->
                            64

                        Nothing ->
                            48

        bodyHeightAttribute =
            Maybe.withDefault [] (Maybe.map (\count -> [ height (px (count * itemHeightPx + 16)) ]) internalConfig.itemsCount)
    in
    Element.el ([ scrollbarY ] ++ bodyAttributes ++ extraAttributes ++ externalAttributes ++ bodyHeightAttribute)
        (Element.column [ width fill, height fill ] (List.map (\item -> listItem config internalConfig data item itemHeightPx) data.items))


listItem : Config item msg -> InternalConfig item -> View item msg -> item -> Int -> Element msg
listItem { theme, lift } internalConfig data item itemHeightPx =
    let
        ( leftPadding, additionalItemAttributes ) =
            case internalConfig.toImageSrc of
                Just toImageSrc ->
                    ( 72
                    , [ height (px itemHeightPx)
                      , inFront (roundImage (toImageSrc item))
                      ]
                    )

                Nothing ->
                    ( 16
                    , [ height (px itemHeightPx) ]
                    )

        colorAttributes =
            if data.activated == Just item then
                Font.color theme.colors.primary.dark
                    :: (htmlAttribute <| Html.Attributes.class "ripple focusPrimaryRipple")
                    :: (if data.state.selected == Just item then
                            [ Background.color theme.colors.primary.lighter ]

                        else
                            [ Background.color theme.colors.primary.lightest
                            , mouseOver [ Background.color theme.colors.primary.lighter ]
                            ]
                       )

            else
                (htmlAttribute <| Html.Attributes.class "ripple focusGrayRipple")
                    :: (if data.state.selected == Just item then
                            [ Background.color theme.colors.gray.light ]

                        else
                            [ mouseOver [ Background.color theme.colors.gray.lightest ] ]
                       )

        itemAttributes =
            [ width fill
            , Font.family [ theme.font.main ]
            , Font.size theme.font.defaultSize
            , Events.onMouseUp (lift <| Select (Just item) (Maybe.map (\onSelect -> onSelect item) data.onSelect))
            ]
                ++ colorAttributes
                ++ additionalItemAttributes

        textAttributes =
            [ width fill
            , paddingEach { top = 0, right = 16, bottom = 0, left = leftPadding }
            , centerY
            ]

        secondaryTextElements =
            case internalConfig.toSecondaryText of
                Just toSecondaryText ->
                    [ Element.el
                        (Font.color theme.colors.gray.color
                            :: Font.size theme.font.smallSize
                            :: textAttributes
                        )
                        (toSecondaryText item |> textWithEllipsis)
                    ]

                Nothing ->
                    []
    in
    Element.column
        itemAttributes
        (Element.el textAttributes (data.toPrimaryText item |> textWithEllipsis)
            :: secondaryTextElements
        )


roundImage : String -> Element msg
roundImage src =
    Element.el [ centerY, paddingXY 16 0 ]
        (html
            (Html.img
                [ Html.Attributes.src src
                , Html.Attributes.alt ""
                , Html.Attributes.width 40
                , Html.Attributes.height 40
                , Html.Attributes.style "border-radius" "50%"
                , Html.Attributes.style "object-fit" "cover"
                ]
                []
            )
        )
