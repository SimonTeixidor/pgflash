module View exposing (..)

import Html exposing (Attribute, Html, br, div, form, h3, input, label, option, p, select, text)
import Html.Attributes exposing (class, id, maxlength, placeholder, type_, value)
import Html.Events exposing (onInput, onSubmit)
import Model exposing (Model, initialState)
import Msg exposing (Msg(..))


view : Model -> Html Msg
view model =
    div [] <|
        List.filterMap (\f -> f model) [ errorDiv, deckListDiv, loginDiv ]


errorDiv : Model -> Maybe (Html Msg)
errorDiv model =
    Maybe.map (\e -> div [ class "error-div" ] [ h3 [] [ text e ] ]) model.error


deckListDiv : Model -> Maybe (Html Msg)
deckListDiv model =
    if List.isEmpty model.decks then
        Nothing
    else
        div [ class "input-box" ]
            [ label [] [ text "Deck:" ]
            , select [ onInput ChangeDeck ] <| List.map (\d -> option [] [ text d.name ]) model.decks
            ]
            |> Just


loginDiv : Model -> Maybe (Html Msg)
loginDiv model =
    case model.token of
        Just _ ->
            Nothing

        Nothing ->
            form [ onSubmit LoginFormSubmit ]
                [ div [] [ label [] [ text "Username" ], input [ onInput UsernameInput ] [] ]
                , div [] [ label [] [ text "Password" ], input [ onInput PasswordInput ] [] ]
                , input [ type_ "submit" ] []
                ]
                |> Just
