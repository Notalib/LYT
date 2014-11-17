window.lytBridge = {
    _queue: [],
    _books: [], // should be updated by native app
    
    _sendCommand: function(commandName, payloadArray) {
        this._queue.push([commandName, payloadArray]);
        window.open('nota://signal');
    },
    
    _consumeCommands: function() {
        var result = JSON.stringify(this._queue);
        this._queue = [];
        return result;
    },
    
    setBook: function(bookData) {
        this._sendCommand('setBook', [bookData]);
    },
    
    clearBook: function(bookId) {
        this._sendCommand('clearBook', [bookId]);
    },
    
    getBooks: function() {
        return this._books;
    },
    
    play: function(bookId, offset) {
        this._sendCommand('play', [bookId, offset]);
    },
    
    stop: function() {
        this._sendCommand('stop', []);
    },
    
    cacheBook: function (bookId) {
        this._sendCommand('cacheBook', [bookId]);
    },
    
    clearBookCache: function (bookId) {
        this._sendCommand('clearBookCache', [bookId]);
    }
};
