module Model exposing (Card, Deck, Model, cardDecoder, deckDecoder, initialState)

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


type alias Model =
    { deck : Maybe Deck
    , decks : List Deck
    , token : Maybe String
    , error : Maybe String
    , username : String
    , password : String
    }


initialState : Model
initialState =
    { deck = Nothing
    , decks = []
    , token = Nothing
    , error = Nothing
    , username = ""
    , password = ""
    }


cardDecoder : Decoder Card
cardDecoder =
    map3 Card (field "front" string) (field "back" string) (field "deck_name" string)


deckDecoder : Decoder Deck
deckDecoder =
    map3 Deck (field "owner" string) (field "name" string) (field "public" bool)
