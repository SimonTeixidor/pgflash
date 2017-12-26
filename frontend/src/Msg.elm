module Msg exposing (Msg(..))

import Http
import Model exposing (Card, Deck)


type Msg
    = DeckList (Result Http.Error (List Deck))
    | ChangeDeck String
    | NewCard Card
    | NewToken (Result Http.Error String)
    | LoginFormSubmit
    | UsernameInput String
    | PasswordInput String
