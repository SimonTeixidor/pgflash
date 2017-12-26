module Update exposing (update)

import Date
import Debug
import Http
import Model exposing (Model)
import Msg exposing (Msg(..))
import Tasks exposing (getDecks, sendLogin)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        DeckList (Err e) ->
            ( { model | error = Just <| httpErrorString e }, Cmd.none )

        DeckList (Ok lst) ->
            Debug.log "New decks"
                ( { model | decks = lst }, Cmd.none )

        ChangeDeck s ->
            ( { model | deck = model.decks |> List.filter (\d -> d.name == s) |> List.head }, Cmd.none )

        NewCard c ->
            ( model, Cmd.none )

        NewToken (Ok s) ->
            ( { model | token = Just s }, getDecks s )

        NewToken (Err e) ->
            ( { model | error = Just <| httpErrorString e }, Cmd.none )

        LoginFormSubmit ->
            ( { model | password = "" }, sendLogin model.username model.password )

        UsernameInput s ->
            ( { model | username = s }, Cmd.none )

        PasswordInput s ->
            ( { model | password = s }, Cmd.none )


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
