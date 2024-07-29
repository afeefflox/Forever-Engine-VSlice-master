package meta.data.events;

class Events
{
    public var delay:Float = 0;
    public var eventId(default, null):String = 'UNKNOWN';

    public function new(eventId:String):Void
    {
        this.eventId = eventId;
    }

    public function percacheFunction(params:Array<String>) {
        trace('Event(${this.eventId}, Values: $params)');
    }
    public function initFunction(params:Array<String>) {
        trace('Event(${this.eventId}, Values: $params)');
    }
    public function returnDescription():String
    {
        return '';
    }

    public function toString()
    {
        return 'Event(' + this.eventId + ')';
    }
}