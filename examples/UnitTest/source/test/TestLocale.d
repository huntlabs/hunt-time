module test.TestLocale;

import hunt.time.util.Locale;

import hunt.logging.ConsoleLogger;

class TestLocale {

    void testBasic() {
        Locale locale = Locale.getDefault();
        trace(locale.toString());
    }
}