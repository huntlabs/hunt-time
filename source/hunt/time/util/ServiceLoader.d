/*
 * hunt-time: A time library for D programming language.
 *
 * Copyright (C) 2015-2018 HuntLabs
 *
 * Website: https://www.huntlabs.net/
 *
 * Licensed under the Apache-2.0 License.
 *
 */

module hunt.time.util.ServiceLoader;

alias Ctor(R) = R delegate();

struct LoaderHanler(T)
{
    Ctor!(T) ctor;
}

struct ServiceLoader(T)
{
    
    __gshared static LoaderHanler!(T)[] objs;

    static public void  register(R)() if(is(R : T))
    {
        auto hanler = delegate T(){ return cast(T)(new R());};
        ServiceLoader!(T).objs ~= LoaderHanler!(T)(hanler);
    }
}


mixin template MakeServiceLoader(T)
{
    alias THIS = typeof(this);
    shared static this()
    {
        ServiceLoader!(T).register!(THIS);
    }
}