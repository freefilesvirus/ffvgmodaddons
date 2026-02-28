require("jpegalizefier")

TOOL.Category="Render"
TOOL.Name="#tool.jpegalizefier.name"

if CLIENT then
    TOOL.Information={
        {name="jpeg",icon="gui/lmb.png"},
        {name="unjpeg",icon="gui/r.png"},
    }

    language.Add("tool.jpegalizefier.name","jpegalizefier")
    language.Add("tool.jpegalizefier.desc","apply awful jpeg compression")
    language.Add("tool.jpegalizefier.jpeg","jpegalizefy")
    language.Add("tool.jpegalizefier.unjpeg","unjpegalizefy")

    function TOOL.BuildCPanel(panel)
        panel:Help("#tool.jpegalizefier.desc")
    end
end

function TOOL:LeftClick(trace)
    if IsValid(trace.Entity) and !trace.HitWorld and !jpegalizefier.GetJPEGalizefied(trace.Entity) then
        if SERVER then
            jpegalizefier.SetJPEGalizefied(trace.Entity,true)
        end

        return true
    end
end

function TOOL:Reload(trace)
    if IsValid(trace.Entity) and !trace.HitWorld and jpegalizefier.GetJPEGalizefied(trace.Entity) then
        if SERVER then
            jpegalizefier.SetJPEGalizefied(trace.Entity,false)
        end

        return true
    end
end
