extensions = {};
extensions.demo = 
{
    ["s"] = function()
        app.wait(1)
        app.answer()
        channel.TIMEOUT("digit"):set(5)
        channel.TIMEOUT("response"):set(10)
        ::restart::
        app.background("demo-congrats")
        ::instructions::
        for x=0, x<3, x="x+1" do 
            ::label0::
            app.background("demo-instruct")
            app.waitExten()
        end;
    end;
    ["2"] = function()
        app.background("demo-moreinfo")
        -- (ael2lua warning) goto a label on a different extension is not supported (original AEL2 target : s|instructions)
    end;
    ["3"] = function()
        channel.LANGUAGE():set("fr")
        -- (ael2lua warning) goto a label on a different extension is not supported (original AEL2 target : s|restart)
    end;
    ["500"] = function()
        app.playback("demo-abouttotry")
        app.dial("IAX2/guest_at_misery.digium.com")
        app.playback("demo-nogo")
        -- (ael2lua warning) goto a label on a different extension is not supported (original AEL2 target : s|instructions)
    end;
    ["600"] = function()
        app.playback("demo-echotest")
        app.echo()
        app.playback("demo-echodone")
        -- (ael2lua warning) goto a label on a different extension is not supported (original AEL2 target : s|instructions)
    end;
    ["#"] = function()
        ::hangup::
        app.playback("demo-thanks")
        app.hangup()
    end;
    ["t"] = app.goto(#,1)
    ["i"] = app.playback("invalid")

};

