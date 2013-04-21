import logging, sys, time, os
import logging.handlers

def setup_logging():

    console_handler = logging.StreamHandler()
    color = False
    if curses and sys.stderr == sys.__stderr__ and sys.stderr.isatty():
        try:
            curses.setupterm()
            if curses.tigetnum("colors") > 0:
                color = True
        except Exception:
            pass
    console_handler.setFormatter(PrettyLogFormatter(color=color))
    console_handler.setLevel(logging.DEBUG)


    logging.getLogger().setLevel(logging.DEBUG)
    logging.getLogger().addHandler(console_handler)


# For pretty log messages, if available
try:
    import curses
except ImportError:
    curses = None

class PrettyLogFormatter(logging.Formatter):
    def __init__(self, color, *args, **kwargs):
        logging.Formatter.__init__(self, *args, **kwargs)
        self._color = color
        if color:
            # The curses module has some str/bytes confusion in python3.
            # Most methods return bytes, but only accept strings.
            # The explict calls to unicode() below are harmless in python2,
            # but will do the right conversion in python3.
            fg_color = unicode(curses.tigetstr("setaf") or
                               curses.tigetstr("setf") or "", "ascii")
            self._colors = {
                logging.DEBUG: unicode(curses.tparm(fg_color, 4), # Blue
                    "ascii"),
                logging.INFO: unicode(curses.tparm(fg_color, 2), # Green
                    "ascii"),
                logging.WARNING: unicode(curses.tparm(fg_color, 3), # Yellow
                    "ascii"),
                logging.ERROR: unicode(curses.tparm(fg_color, 1), # Red
                    "ascii"),
                }
            self._normal = unicode(curses.tigetstr("sgr0"), "ascii")

    def format(self, record):
        try:
            record.message = record.getMessage()
        except Exception, e:
            record.message = "Bad message (%r): %r" % (e, record.__dict__)
        record.asctime = time.strftime(
            "%y%m%d %H:%M:%S", self.converter(record.created))
        prefix = '[%(levelname)1.1s %(asctime)s %(name)s:%(lineno)d]' %\
                 record.__dict__
        if self._color:
            prefix = (self._colors.get(record.levelno, self._normal) +
                      prefix + self._normal)
        formatted = prefix + " " + record.message
        if record.exc_info:
            if not record.exc_text:
                record.exc_text = self.formatException(record.exc_info)
        if record.exc_text:
            formatted = formatted.rstrip() + "\n" + record.exc_text
        return formatted.replace("\n", "\n    ")
