import collections

class EventSource(object):
    def __init__(self):
        self.listeners = collections.defaultdict(list)

    def bind(self, event, listener):
        self.listeners[event].append(listener)

    def unbind(self, event, listener):
        self.listeners[event].remove(listener)

    def trigger(self, event, *args, **kwds):
        for listener in self.listeners[event]:
            listener(*args, **kwds)