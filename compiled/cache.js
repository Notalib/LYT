(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  this.cache = __bind(function() {
    var getCache, getTimestamp, read, remove, removeCache, removeOldest, write;
    read = function(prefix, id) {
      var cache;
      if (window.localStorage == null) {
        return null;
      }
      cache = getCache("" + prefix + "/" + id);
      return (cache != null ? cache.data : void 0) || null;
    };
    write = function(prefix, id, data) {
      var cache, success;
      if (window.localStorage == null) {
        return null;
      }
      removeCache("" + prefix + "/" + id);
      if (typeof data !== "object") {
        data = String(data);
      }
      cache = {
        type: typeof data,
        data: data,
        timestamp: getTimestamp()
      };
      success = false;
      while (!success) {
        try {
          localStorage.setItem("" + prefix + "/" + id, JSON.stringify(cache));
          success = true;
        } catch (error) {
          if (error === QUOTA_EXCEEDED_ERR) {
            removeOldest(prefix);
          } else {
            break;
          }
        }
      }
      return success;
    };
    remove = function(prefix, id) {
      if (window.localStorage == null) {
        return null;
      }
      return removeCache("" + prefix + "/" + id);
    };
    getCache = function(key) {
      var cache;
      if (window.localStorage == null) {
        return null;
      }
      cache = localStorage.getItem(key);
      if (!(cache && (cache = JSON.parse(cache)))) {
        return null;
      }
      return cache;
    };
    removeCache = function(key) {
      try {
        return localStorage.removeItem(key);
      } catch (error) {

      }
    };
    getTimestamp = function() {
      return (new Date).getTime();
    };
    removeOldest = function(prefix) {
      var cache, index, key, oldestKey, oldestTimestamp, _ref;
      oldestTimestamp = getTimestamp();
      oldestKey = false;
      for (index = 0, _ref = localStorage.length; 0 <= _ref ? index <= _ref : index >= _ref; 0 <= _ref ? index++ : index--) {
        key = localStorage.key(index);
        if ((key != null ? key.indexOf(prefix) : void 0) === 0) {
          cache = getCache(key);
          if (cache.timestamp < oldestTimestamp) {
            oldestTimestamp = cache.timestamp;
            oldestKey = key;
          }
        }
      }
      if (oldestKey) {
        return removeCache(key);
      }
    };
    return {
      read: read,
      write: write,
      remove: remove
    };
  }, this)();
}).call(this);
