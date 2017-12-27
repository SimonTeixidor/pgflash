module Update exposing (update)

import Date
import Debug
import Http
import Model exposing (Model(..))
import Msg exposing (Msg(..))
import Tasks exposing (getCard, getDecks, sendCardAnswer, sendLogin)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg m =
    case m of
        NotLoggedIn ({ username, password } as model) ->
            case msg of
                UsernameInput s ->
                    ( NotLoggedIn { model | username = s }, Cmd.none )

                PasswordInput s ->
                    ( NotLoggedIn { model | password = s }, Cmd.none )

                LoginFormSubmit ->
                    ( NotLoggedIn { model | password = "" }
                    , sendLogin username password
                    )

                NewToken (Ok s) ->
                    ( DeckChoice { error = Nothing, token = s, decks = [] }
                    , getDecks s
                    )

                NewToken (Err e) ->
                    ( NotLoggedIn { model | error = Just <| httpErrorString e }, Cmd.none )

                _ ->
                    ( NotLoggedIn model, Cmd.none )

        DeckChoice ({ decks, token } as model) ->
            case msg of
                DeckList (Ok lst) ->
                    ( DeckChoice { model | decks = lst }, Cmd.none )

                DeckList (Err e) ->
                    ( DeckChoice { model | error = Just <| httpErrorString e }, Cmd.none )

                ChangeDeck s ->
                    ( DeckChoice model, getCard token s )

                NewCard (Ok (c :: _)) ->
                    ( Answer { error = Nothing, card = c, answer = "", token = token }
                    , Cmd.none
                    )

                NewCard (Ok []) ->
                    ( DeckChoice { model | error = Just "Couldn't find any cards in deck." }, Cmd.none )

                NewCard (Err e) ->
                    ( DeckChoice { model | error = Just <| httpErrorString e }, Cmd.none )

                _ ->
                    ( DeckChoice model, Cmd.none )

        Answer ({ card, answer, token } as model) ->
            case msg of
                CardAnswer ->
                    ( Answer { model | answer = "" }
                    , sendCardAnswer token card (model.answer == card.back)
                    )

                CardAnswerInput s ->
                    ( Answer { model | answer = s }, Cmd.none )

                CardAnswerResponse (Ok _) ->
                    ( Answer model, getCard token card.deck_name )

                CardAnswerResponse (Err e) ->
                    ( Answer { model | error = Just <| httpErrorString e }, Cmd.none )

                _ ->
                    ( Answer model, Cmd.none )


httpErrorString : Http.Error -> String
httpErrorString e =
    case e of
        Http.BadUrl _ ->
            "The server URL is not well formed."

        Http.Timeout ->
            "The server timed out, try again later."

        Http.NetworkError ->
            "Lost network connection."

        Http.BadStatus resp ->
            toString resp.status

        Http.BadPayload req res ->
            "Could not interpret response from server: " ++ req ++ " " ++ toString res
