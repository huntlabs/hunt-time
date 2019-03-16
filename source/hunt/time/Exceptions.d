module hunt.time.Exceptions;

import hunt.Exceptions;

class DateTimeException : Exception {
    mixin BasicExceptionCtors;
}

class UnsupportedTemporalTypeException : DateTimeException {
    mixin BasicExceptionCtors;
}