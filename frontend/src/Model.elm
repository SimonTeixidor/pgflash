module Model exposing (Card, Deck, Model(..), cardDecoder, deckDecoder, initialState)

import Json.Decode exposing (..)


type alias Card =
    { front : String
    , back : String
    , deck_name : String
    }


type alias Deck =
    { owner : String
    , name : String
    , public : Bool
    }


type Model
    = NotLoggedIn { error : Maybe String, username : String, password : String }
    | DeckChoice { error : Maybe String, token : String, decks : List Deck }
    | Answer { error : Maybe String, token : String, card : Card, answer : String }
    | ShowAnswer { error : Maybe String, token : String, card : Card, answer : String }


initialState : Model
initialState =
    NotLoggedIn { error = Nothing, username = "", password = "" }


cardDecoder : Decoder Card
cardDecoder =
    map3 Card (field "front" string) (field "back" string) (field "deck_name" string)


deckDecoder : Decoder Deck
deckDecoder =
    map3 Deck (field "owner" string) (field "name" string) (field "public" bool)
