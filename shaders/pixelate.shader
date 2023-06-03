HEADER
{
	Description = "Retro Pixelation + Low Bit Colour + Dither Post Effect";
}

FEATURES
{
}

MODES
{
    VrForward();
    Default();
}


COMMON
{
	#include "postprocess/shared.hlsl"
}

struct VertexInput
{
    float3 vPositionOs : POSITION < Semantic( PosXyz ); >;
    float2 vTexCoord : TEXCOORD0 < Semantic( LowPrecisionUv ); >;
};

struct PixelInput
{
    float2 vTexCoord : TEXCOORD0;

	// VS only
	#if ( PROGRAM == VFX_PROGRAM_VS )
		float4 vPositionPs		: SV_Position;
	#endif

	// PS only
	#if ( ( PROGRAM == VFX_PROGRAM_PS ) )
		float4 vPositionSs		: SV_ScreenPosition;
	#endif
};

VS
{
    PixelInput MainVs( VertexInput i )
    {
        PixelInput o;
        o.vPositionPs = float4(i.vPositionOs.xyz, 1.0f);
        o.vTexCoord = i.vTexCoord;
        return o;
    }
}

PS
{
    #include "postprocess/common.hlsl"

    float g_pixelationScale< Default( 0.25f ); Range(0.0f, 1.0f); UiGroup( "" ); >;
    float g_ditherStrength< Default( 0.01f ); Range(0.0f, 1.0f); UiGroup( "" ); >;
    float g_ditherScale< Default( 0.5f ); Range(0.0f, 1.0f); UiGroup( "" ); >;
    float3 g_colorDepth< Default3( 8, 16, 8 ); Range3(0, 0, 0, 255, 255, 255); UiGroup( "" ); >;

    RenderState( DepthWriteEnable, false );
    RenderState( DepthEnable, false );

    CreateTexture2D( g_tColorBuffer ) < Attribute( "ColorBuffer" );  	SrgbRead( true ); Filter( MIN_MAG_LINEAR_MIP_POINT ); AddressU( MIRROR ); AddressV( MIRROR ); >;
    CreateTexture2D( g_tDepthBuffer ) < Attribute( "DepthBuffer" ); 	SrgbRead( false ); Filter( MIN_MAG_MIP_POINT ); AddressU( CLAMP ); AddressV( CLAMP ); >;

    static const float4x4 ditherTable = 
    {
    -4.0, 0.0, -3.0, 1.0,
    2.0, -2.0, 3.0, -1.0,
    -3.0, 1.0, -4.0, 0.0,
    3.0, -1.0, 2.0, -2.0
    };

    float4 MainPs( PixelInput i ) : SV_Target0
    {
        float4 o;
        //Pixelation stepping
        float2 frameDimensions;
        g_tColorBuffer.GetDimensions(frameDimensions.x, frameDimensions.y);
        float2 cellSize = frameDimensions * g_pixelationScale;
        float2 steppedUv = i.vTexCoord.xy;
        steppedUv *= cellSize;
        steppedUv = round(steppedUv);
        steppedUv /= cellSize;

        o = Tex2D(g_tColorBuffer, steppedUv);

        //Dither
        uint2 pixelCoord = (i.vTexCoord.xy * frameDimensions) * g_ditherScale;
        o += ditherTable[pixelCoord.x % 4][pixelCoord.y % 4] * (g_ditherStrength * 0.5);

        //Color depth stepping
        float3 steppedColor = o.rgb;
        steppedColor *= g_colorDepth;
        steppedColor = round(steppedColor);
        steppedColor /= g_colorDepth;

        o.rgb = steppedColor;
        return o;
    }
}