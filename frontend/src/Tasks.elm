module Tasks exposing (getCard, getDecks, sendCardAnswer, sendLogin)

import Conf exposing (baseUrl)
import Http
import Json.Decode as JsonD
import Json.Encode as JsonE
import Model exposing (Card, Deck, cardDecoder, deckDecoder)
import Msg exposing (Msg(..))
import QueryString as QS


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


getCard : String -> String -> Cmd Msg
getCard token deck =
    let
        url =
            baseUrl ++ "/next_card" ++ (QS.render <| QS.add "deck_name" ("eq." ++ deck) QS.empty)
    in
    Http.request
        { method = "GET"
        , headers = [ Http.header "Authorization" ("Bearer " ++ token) ]
        , url = url
        , body = Http.emptyBody
        , expect = Http.expectJson (JsonD.list cardDecoder)
        , timeout = Nothing
        , withCredentials = False
        }
        |> Http.send NewCard


sendCardAnswer : String -> Card -> Bool -> Cmd Msg
sendCardAnswer token card remembered =
    Http.request
        { method = "POST"
        , headers = [ Http.header "Authorization" ("Bearer " ++ token) ]
        , url = baseUrl ++ "/rpc/card_answer"
        , body =
            Http.jsonBody
                (JsonE.object
                    [ ( "f", JsonE.string card.front )
                    , ( "b", JsonE.string card.back )
                    , ( "dn", JsonE.string card.deck_name )
                    , ( "a"
                      , JsonE.string <|
                            if remembered then
                                "remembered"
                            else
                                "not_remembered"
                      )
                    ]
                )
        , expect = Http.expectJson JsonD.string
        , timeout = Nothing
        , withCredentials = False
        }
        |> Http.send CardAnswerResponse
