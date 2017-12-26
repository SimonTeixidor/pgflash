module Main exposing (..)

import Html
import Model exposing (initialState)
import Task
import Tasks exposing (sendLogin)
import Update exposing (update)
import View exposing (view)


main =
    Html.program
        { init =
            ( initialState
            , Cmd.none
            )
        , view = view
        , update = update
        , subscriptions = always Sub.none
        }
