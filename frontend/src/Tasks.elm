module Tasks exposing (getDecks, sendLogin)

import Conf exposing (baseUrl)
import Http
import Json.Decode as JsonD
import Json.Encode as JsonE
import Model exposing (cardDecoder, deckDecoder)
import Msg exposing (Msg(..))


sendLogin : String -> String -> Cmd Msg
sendLogin user pass =
    let
        request =
            Http.post
                (baseUrl ++ "/rpc/login")
                (Http.jsonBody (JsonE.object [ ( "name", JsonE.string user ), ( "pass", JsonE.string pass ) ]))
                JsonD.string
    in
    Http.send NewToken request


getDecks : String -> Cmd Msg
getDecks token =
    Http.request
        { method = "GET"
        , headers = [ Http.header "Authorization" ("Bearer " ++ token) ]
        , url = baseUrl ++ "/deck"
        , body = Http.emptyBody
        , expect = Http.expectJson (JsonD.list deckDecoder)
        , timeout = Nothing
        , withCredentials = False
        }
        |> Http.send DeckList
