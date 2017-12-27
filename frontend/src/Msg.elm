module Msg exposing (Msg(..))

import Http
import Model exposing (Card, Deck)


type Msg
    = DeckList (Result Http.Error (List Deck))
    | ChangeDeck String
    | NewCard (Result Http.Error (List Card))
    | NewCardRequest
    | NewToken (Result Http.Error String)
    | LoginFormSubmit
    | UsernameInput String
    | PasswordInput String
    | CardAnswer
    | CardAnswerInput String
    | CardAnswerResponse (Result Http.Error String)
