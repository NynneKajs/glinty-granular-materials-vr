Shader "Unlit/UICutout"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}
        _Color("Color",  Color) = (1,1,1,1)
        _Emission("Emission", Range(0,10)) = 1
    }
    SubShader
    {
        Tags {"Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "TransparentCutout"}
        ZWrite Off
        Blend SrcAlpha OneMinusSrcAlpha
        Cull back
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "/Includes/Helpers.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _Color;
            float _Emission;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                // sample the texture
                fixed4 tex = tex2D(_MainTex, i.uv);
                float texIntensity = tex.a > 0 ? 1 : 0;
                fixed4 col = fixed4(texIntensity, texIntensity, texIntensity, tex.a);
                col.rgb *= _Color.rgb;
                col.rgb *= _Emission;
                col.a = saturate(col.a);
                return col;
            }
            ENDCG
        }
    }
}
