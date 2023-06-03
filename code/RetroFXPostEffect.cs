using Sandbox;

namespace RetroFX;

[SceneCamera.AutomaticRenderHook]
public class RetroFXPostEffect : RenderHook
{
    [ConVar.Replicated("retrofx_enabled", Help = "Show RetroFX post processing effect?")]
    public bool EnabledConVar { get; set; } = true;

    [ConVar.Replicated("retrofx_scale"), Change(nameof(OnConVarChanged))]
    public float Scale { get; set; } = 0.25f;

    [ConVar.Replicated("retrofx_ditherscale"), Change(nameof(OnConVarChanged))]
    public float DitherScale { get; set; } = 0.5f;

    [ConVar.Replicated("retrofx_colourdepth"), Change(nameof(OnConVarChanged))]
    public int ColourDepth { get; set; } = 16;

    [ConVar.Replicated("retrofx_ditherstrength"), Change(nameof(OnConVarChanged))]
    public float DitherStrength { get; set; } = 0.01f;

    private bool cvarsDirty = true;

    RenderAttributes attributes = new RenderAttributes();
    Material material = Material.Load("materials/retrofxpost.vmat");

    private void OnConVarChanged()
    {
        cvarsDirty = true;
    }

    public override void OnStage(SceneCamera target, Stage renderStage)
    {
        if (EnabledConVar && renderStage == Stage.BeforePostProcess)
        {
            if(cvarsDirty)
            {
                attributes.Set("scale", Scale);
                attributes.Set("depth", new Vector3(ColourDepth, ColourDepth, ColourDepth));
                attributes.Set("dither_scale", DitherScale);
                attributes.Set("dither_strength", DitherStrength);
                //cvarsDirty = false;
            }

            Graphics.GrabFrameTexture("ColorBuffer", attributes, withMips: false);

            Graphics.Blit(material, attributes);
        }
    }
}