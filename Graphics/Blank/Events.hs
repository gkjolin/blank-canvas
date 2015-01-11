{-# LANGUAGE CPP, OverloadedStrings, ScopedTypeVariables, TemplateHaskell #-}
module Graphics.Blank.Events where

#if !(MIN_VERSION_base(4,8,0))
import Control.Applicative ((<*>))
#endif
import Control.Applicative ((<|>), (<$>))
import Control.Concurrent.STM

import Data.Aeson (FromJSON(..), Value(..), ToJSON(..))
import Data.Aeson.Types ((.:), (.=), object)
import Data.Text (Text)

import Text.Show.Text.TH (deriveShow)

-- | 'EventName' mirrors event names from jquery, and use lower case.
--   Possible named events
--
--     * keypress, keydown, keyup
--     * mouseDown, mouseenter, mousemove, mouseout, mouseover, mouseup
-- 
type EventName = Text

-- | EventQueue is a STM channel ('TChan') of 'Event's.
-- Intentionally, 'EventQueue' is not abstract.
type EventQueue = TChan Event

-- | Basic Event from Browser; see <http://api.jquery.com/category/events/> for details.
data Event = Event
        { eMetaKey :: Bool
        , ePageXY  :: Maybe (Double, Double)
        , eType    :: EventName          -- "Describes the nature of the event." jquery
        , eWhich   :: Maybe Int          -- magic code for key presses
        }
        deriving (Show)
$(deriveShow ''Event)

instance FromJSON Event where
   parseJSON (Object v) = Event <$> ((v .: "metaKey")              <|> return False)
                                <*> (Just <$> (v .: "pageXY")      <|> return Nothing)
                                <*> (v .: "type")
                                <*> (Just <$> (v .: "which")       <|> return Nothing)
   parseJSON _ = fail "no parse of Event"    

instance ToJSON Event where
   toJSON e = object 
            $ ((:) ("metaKey" .=  eMetaKey e))
            $ (case ePageXY e of
                 Nothing -> id
                 Just (x,y) -> (:) ("pageXY" .= (x,y)))
            $ ((:) ("type" .= eType e))
            $ (case eWhich e of
                 Nothing -> id
                 Just w -> (:) ("which" .= w))
            $ []
