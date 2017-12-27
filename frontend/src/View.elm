module View exposing (..)

import Html exposing (Attribute, Html, br, button, div, form, h3, input, label, option, p, select, text)
import Html.Attributes exposing (class, id, maxlength, placeholder, type_, value)
import Html.Events exposing (onInput, onSubmit)
import Model exposing (Model(..), initialState)
import Msg exposing (Msg(..))


view : Model -> Html Msg
view model =
    div [] <|
        List.filterMap (\f -> f model) [ errorDiv, deckListDiv, loginForm, cardDiv ]


errorDiv : Model -> Maybe (Html Msg)
errorDiv model =
    -- TODO: Find way to not pattern match over each state, as they all have error.
    case model of
        NotLoggedIn { error } ->
            Maybe.map (\e -> div [ class "error-div" ] [ h3 [] [ text e ] ]) error

        DeckChoice { error } ->
            Maybe.map (\e -> div [ class "error-div" ] [ h3 [] [ text e ] ]) error

        Answer { error } ->
            Maybe.map (\e -> div [ class "error-div" ] [ h3 [] [ text e ] ]) error

        ShowAnswer { error } ->
            Maybe.map (\e -> div [ class "error-div" ] [ h3 [] [ text e ] ]) error


deckListDiv : Model -> Maybe (Html Msg)
deckListDiv model =
    case model of
        DeckChoice { decks, token } ->
            if not <| List.isEmpty decks then
                div [ class "input-box" ]
                    [ label [] [ text "Deck:" ]
                    , select [ onInput ChangeDeck ] <| List.map (\d -> option [] [ text d.name ]) decks
                    ]
                    |> Just
            else
                Nothing

        _ ->
            Nothing


loginForm : Model -> Maybe (Html Msg)
loginForm model =
    case model of
        NotLoggedIn _ ->
            div [ class "input-box" ]
                [ form [ onSubmit LoginFormSubmit ]
                    [ div [] [ label [] [ text "Username" ], input [ onInput UsernameInput ] [] ]
                    , div [] [ label [] [ text "Password" ], input [ onInput PasswordInput ] [] ]
                    , input [ type_ "submit" ] []
                    ]
                ]
                |> Just

        _ ->
            Nothing


cardDiv : Model -> Maybe (Html Msg)
cardDiv model =
    case model of
        Answer { card, answer } ->
            div [ id "card" ]
                [ div [ class "card-side" ]
                    [ p [] [ text "Front" ]
                    , h3 [ id "card-front" ] [ text card.front ]
                    ]
                , form [ onSubmit CardAnswer ]
                    [ input
                        [ placeholder "Answer"
                        , onInput CardAnswerInput
                        , value answer
                        ]
                        []
                    , button [] [ text "Submit" ]
                    ]
                ]
                |> Just

        ShowAnswer { card, answer } ->
            div [ id "card" ]
                [ div [ class "card-side" ]
                    [ p [] [ text "Front" ]
                    , h3 [ id "card-front" ] [ text card.front ]
                    ]
                , div [ class "card-side" ]
                    [ p [] [ text "Back" ]
                    , h3 [ id "card-back" ] [ text card.back ]
                    ]
                , form [ onSubmit NewCardRequest ]
                    [ button [] [ text "Next Card" ] ]
                ]
                |> Just

        _ ->
            Nothing
