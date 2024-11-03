package meta.data.events;

class SongEvent
{
    public var id:String;

    public function new(id:String)
    {
      this.id = id;
    }

    public function handleEvent(data:SongEventData):Void
    {
      throw 'SongEvent.handleEvent() must be overridden!';
    }

    public function precacheEvent(data:SongEventData):Void {}

    public function getEventSchema():SongEventSchema return null;

    public function getTitle():String return this.id.toTitleCase();

    public function toString():String return 'SongEvent(${this.id})';
}