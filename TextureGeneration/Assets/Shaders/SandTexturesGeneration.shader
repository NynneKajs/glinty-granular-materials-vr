Shader "Custom/SandTexturesGeneration"
{
    Properties
    {

	[HideInInspector] _Jitter("Jitter for Noise", Range(0.44, 1.44)) = 1.44
	[Header(Noise)]

	[IntRange] _Layers("Number of Layers", Range(0,15)) = 10
	_Thresh("Distance between Grains", Range(0,1)) = 0.3
	_RoundAmp("Roundness of Grains", Range(0,1)) = 0.28
	_Seed("Random Seed", Range(0, 1)) = 0


	[Header(Colors)]
	_Color("Base Color", Color) = (1,1,1,1)
	_Color0("Color0", Color) = (1,1,1,1)
	[IntRange]_Weight0("Color0 %", Range(0,100)) = 25
	_Color1("Color1", Color) = (1,1,1,1)
	[IntRange]_Weight1("Color1 %", Range(0,100)) = 25
	_Color2("Color2", Color) = (1,1,1,1)
	[IntRange]_Weight2("Color2 %", Range(0,100)) = 25
	_Color3("Color3", Color) = (1,1,1,1)
	[IntRange]_Weight3("Color3 %", Range(0,100)) = 25
	_LayerDarkness("Layer Occlusion", Range(0,1)) = 0.8


	[HideInInspector] [IntRange]_OutputType("_OutputType", Range(0,4)) = 0
	[HideInInspector] [IntRange]_ENABLE_UVVIEW("Enable UV View", Range(0,1)) = 0
	[HideInInspector] _AverageColor("Average Color", Color) = (1,1,1,1)
	[HideInInspector] _SampleDistance("Distance for Sampling Slope Values", Range(0,1)) = 0.001
	[HideInInspector] [IntRange]_CellAmount("Cell Amount", Range(1,4)) = 1
	[HideInInspector] [IntRange]_Period("Repeat every X cells", Range(0,100)) = 36 // 14

    }
    SubShader
    {
        Pass
        {
			Name "FORWARD"
			Tags {
				"LightMode" = "ForwardBase" "RenderType" = "Opaque"
			}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
			#include "UnityCG.cginc"
			#include "AutoLight.cginc"
			#include "Lighting.cginc"
			#include "/Includes/Helpers.cginc"
			#include "/Includes/Shading.cginc"
			#include "/Includes/RandomGeneration.cginc"
			#pragma multi_compile_fwdbase
			#pragma shader_feature _RECEIVE_SHADOWS_ON
			#pragma target 4.0

            struct appdata
            {
                float4 vertex : POSITION;
				float3 normal : NORMAL; 
				float3 tangent : TANGENT;
                float4 uv : TEXCOORD0;
				float2 texcoord1 : TEXCOORD1;  
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
				float4 uv : TEXCOORD0;
				float3 normalDirection : TEXCOORD1;    
				float3 tangent : TEXCOORD2;
				float3 worldPos : TEXCOORD3;		
				LIGHTING_COORDS(4,5)                 
            };

			// Colors
			float4 _Color;
			float4 _Color0;
			float4 _Color1;
			float4 _Color2;
			float4 _Color3;
			float _Weight0;
			float _Weight1;
			float _Weight2;
			float _Weight3;
			float _LayerDarkness;

			// Noise Variables
			float _RoundAmp;
			int _Layers;
			float _Thresh;
			int _NoiseScale;
			float _Seed;

			// Hidden
			int _OutputType;
			int _ENABLE_UVVIEW;
			float _SampleDistance;
			float4 _AverageColor;
			int _CellAmount;
			int _Period;
			float _Jitter;

			float accWeights(int index) {
				float acc = 0;
				float weights[] = { _Weight0 / 100, _Weight1 / 100, _Weight2 / 100, _Weight3 / 100 };
				for (int i = 0; i <= index; i++)
					acc += weights[i];
				return acc;
			}

			int weightedColorIndex(float r) {
				r = r;
				int index;
				if (r <= accWeights(0))
					index = 0;
				else if (r <= accWeights(1))
					index = 1;
				else if (r <= accWeights(2))
					index = 2;
				else 
					index = 3;
				return index;
			}
			float3 randomColorValue(float value) {

				float3 rand = float3(
					rand1dTo1d(value, 3.9812),
					rand1dTo1d(value, 7.1536),
					rand1dTo1d(value, 5.7241)
					);
				float4 C[] = {
					_Color0,
					_Color1,
					_Color2,
					_Color3,
				};

				return  C[weightedColorIndex(saturate(rand.x))].rgb;

			}

			float3 averageColor() {
				float3 P1 = accWeights(0) < 1 ? _Color0 * _Weight0 : _Color;
				float3 P2 = accWeights(1) < 1 ? _Color1 * _Weight1 : _Color * max(0, 1 - accWeights(0));
				float3 P3 = accWeights(2) < 1 ? _Color2 * _Weight2 : _Color * max(0, 1 - accWeights(1));
				float3 P4 = accWeights(3) < 1 ? _Color3 * _Weight3 : _Color * max(0, 1 - accWeights(2));
				return P1 + P2 + P3 + P4;
			}

			// fractal sum, range -1.0 - 1.0
			float fBm_F0(float3 p)
			{
				int octaves = 1;
				float amp = _RoundAmp * 10;
				float2 F = voronoiNoise(p, _Period, _Jitter).xy * amp;
				float sum = 0.1 + sqrt(F[0]);
				return sum;
			}

			float fBm_F1_F0(float3 p)
			{
				float amp = 0.64;
				float2 F = voronoiNoise(p, _Period, _Jitter).xy * amp;
				float sum = 0.1 + sqrt(F[1]) - sqrt(F[0]);
				return sum;
			}

			float thresholded_fBm_F0(float3 pos)
			{
				float noise = saturate(max(0, fBm_F1_F0(float3(pos.x, pos.y, pos.z))));
				return noise > _Thresh ? noise : 0;
			}

			float3 slope(float3 pos) {
				float x_jitter = _SampleDistance; float y_jitter = _SampleDistance; float z_jitter = _SampleDistance;

				float currentPosNoise = thresholded_fBm_F0(float3(pos.x, pos.y, pos.z));

				float xPositiveDirNoise = thresholded_fBm_F0(float3(pos.x + x_jitter, pos.y, pos.z));
				float yPositiveDirNoise = thresholded_fBm_F0(float3(pos.x, pos.y + y_jitter, pos.z));
				float zPositiveDirNoise = thresholded_fBm_F0(float3(pos.x, pos.y, pos.z + z_jitter));

				float xNegativeDirNoise = thresholded_fBm_F0(float3(pos.x - x_jitter, pos.y, pos.z));
				float yNegativeDirNoise = thresholded_fBm_F0(float3(pos.x, pos.y - y_jitter, pos.z));
				float zNegativeDirNoise = thresholded_fBm_F0(float3(pos.x, pos.y, pos.z - z_jitter));

				float3 slope = float3((xPositiveDirNoise - xNegativeDirNoise) / (2 * x_jitter), 
									  (yPositiveDirNoise - yNegativeDirNoise) / (2 * y_jitter),
									  (zPositiveDirNoise - zNegativeDirNoise) / (2 * z_jitter));
				
				// Change values to be appropriate for tangent normal map
				float tempy = slope.y;
				slope.y = slope.z;
				slope.z = tempy;
				slope.z = sqrt(slope.x * slope.x + slope.z * slope.z);
				slope.x  *= -1;
				slope.y  *= -1;

				return (slope);
			}


			void slopeLoop(float3 pos, int numLayers, out float3 slopesOut, out float3 colorsOut, out float heightOut, out float glintsOut, bool makeRound = true) {
				float3 slopes = float3(0, 0, 0);
				float3 color = float3(0, 0, 0);
				float roundNoise = 1;
				float glints = 0;
				float height;
				float offset = 100;

				for (int i = 0; i < numLayers; i++) {
					float3 currPos = float3(pos.x + i * offset, pos.y + i * offset, pos.z + i * offset);
					float3 tempSlopes = slope(currPos);
					float3 noise = thresholded_fBm_F0(currPos);

					if (makeRound) {
						roundNoise = 1 - max(0, fBm_F0(currPos));
					}
					float3 inoiseOut = voronoiNoise(currPos, _Period, _Jitter);
					float3 tempColor = randomColorValue(inoiseOut.z);
					tempColor *= intensity(saturate(tempSlopes)) > 0;
					slopes += (intensity(slopes) == 0 || i == 0) ? tempSlopes * (roundNoise > 0) : float3(0, 0, 0);
					color += (intensity(color) == 0 || i == 0) ? tempColor * (roundNoise > 0) * max(0.4, (1 - i * (_LayerDarkness * 0.624))) : float3(0, 0, 0);
					glints += (glints == 0 && i == 0) ? inoiseOut.z * (intensity(saturate(tempSlopes)) > 0) * (roundNoise > 0) : 0;
					height += (height == 0 || i == 0) ? noise.z * (intensity(saturate(tempSlopes)) > 0) * (roundNoise > 0) : 0;

				}
				slopes.z = height > 0 ? height : 1; // To build tangent normal map 
				color = intensity(color) == 0 ? _Color : color;
				slopesOut = slopes;
				colorsOut = color;
				heightOut = height;
				glintsOut = glints;
			}
			
			struct VertexInput {
				float4 vertex : POSITION;       
				float3 normal : NORMAL;         
				float4 tangent : TANGENT;
				float2 uv : TEXCOORD0;   

			};

			struct VertexOutput {
				float4 vertex : SV_POSITION;              
				float2 uv : TEXCOORD0;               
				float4 pos : TEXCOORD1;                
				float3 normalDirection : TEXCOORD3;    
				float4 tangent : TEXCOORD4;
				float3 worldPos : TEXCOORD5;		   
				float3 objectPos : TEXCOORD6;		   
				LIGHTING_COORDS(7, 8)                   
			};


			VertexOutput vert(VertexInput v) {
				// UV_VIEW relates to baking the texture
				// Shader baking approach from https://github.com/sneha-belkhale/shader-bake-unity
				VertexOutput o = (VertexOutput)0;
				if (_ENABLE_UVVIEW == 0)
					o.vertex = UnityObjectToClipPos(v.vertex);

				else {
					v.vertex = float4(v.uv.xy, 0.0, 1.0);
					o.vertex = mul(UNITY_MATRIX_P, v.vertex);
				}
			
				o.objectPos = v.vertex;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex);
				o.normalDirection = UnityObjectToWorldNormal(v.normal);
				o.tangent = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);
				o.uv = v.uv;
				TRANSFER_SHADOW(o);
				TRANSFER_VERTEX_TO_FRAGMENT(o);
				return o;
			}

            
			fixed4 frag(VertexOutput i) : SV_Target
			{
				
				float3 value = float3(i.uv.x, _Seed, i.uv.y) * _CellAmount * _Period;
				float3 slopes; float3 colors; float glints; float height;
				slopeLoop(value, _Layers, slopes, colors, height, glints);
				slopes = normalize(slopes);
				slopes = (slopes + 1) / 2; 
				slopes = saturate(slopes);

				float3 result = float3(0, 0, 0);
				float3 shade = float3(0, 0, 0);
				
				float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
				float3 lightDirection = normalize(lerp(_WorldSpaceLightPos0.xyz, _WorldSpaceLightPos0.xyz - i.worldPos.xyz, _WorldSpaceLightPos0.w));
				float3 macroNormalDirection = i.normalDirection;
				float3 microNormalDirection = -(slopes * 2 - 1).xzy;
				microNormalDirection = microNormalDirection.xzy;
				microNormalDirection = normalize(microNormalDirection+macroNormalDirection);

				float3 macroViewReflectDirection = normalize(reflect(-viewDirection, macroNormalDirection));

				// Diffuse
				shade = (colors / PI) * _LightColor0 * Lambert(lightDirection, microNormalDirection);

				// The following is ambient
				UnityGI gi_macro = GetUnityGI(_LightColor0.rgb, lightDirection, macroNormalDirection, viewDirection, macroViewReflectDirection, 1, 1, i.worldPos.xyz);
				shade += (colors / PI) * max(1.2, intensity(gi_macro.indirect.specular.rgb)) * float3(1, 1, 1);

				// Used for baking different types of textures
				if (_OutputType == 0)
					result = slopes;
				else if (_OutputType == 1)
					result = colors;
				else if (_OutputType == 2)
					result = float3(glints, glints, glints);
				else if (_OutputType == 3)
					result = float3(_AverageColor.rgb);
				else
					result = shade;
				return float4(result, 1);
            }
            ENDCG
        }
    }
}