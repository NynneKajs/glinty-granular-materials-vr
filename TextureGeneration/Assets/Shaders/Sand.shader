Shader "Custom/Sand" {
	Properties{
	[Header(Normals)]
	[IntRange] _NoiseScale("Noise Scale", Range(1,50000)) = 2000
	_SlopeTex("Slopes Texture", 2D) = "white" {}
	_ColorTex("Colors Texture", 2D) = "white" {}
	_GlintTex("Glints Texture", 2D) = "white" {}
	_AverageColorTex("Average Color", 2D) = "white" {}
	_Height("Height Scale", Range(0.5,200)) = 1
	_SteepX("Steep X", 2D) = "bump" {}
	_ShallowX("Shallow X", 2D) = "bump" {}
	_SteepZ("Steep Z", 2D) = "bump" {}
	_ShallowZ("Shallow Z", 2D) = "bump" {}
	[IntRange] _RipplesSteepFrequency("Ripples Steep Frequency", Range(1,2000)) = 500
	[IntRange] _RipplesShallowFrequency("Ripples Shallow Frequency", Range(1,2000)) = 800
	_SteepnessSharpnessPower("Ripples Steapness", Range(0.001,2)) = 0.8
	_RipplesStrength("Ripples Strength", Range(0,1)) = 0.8
	_SandDetails("Sand Details", 2D) = "bump" {}
	_SandDetailsFrequency("Sand Details Frequency", Range(0.1,2000)) = 500
	_DetailsStrength("Details Strength", Range(0,1)) = 0.8
	[IntRange] _NumDims("Number of Samples per Column for Textures", Range(0,25)) = 5 
	_SampleDistance("Sample Distance for Textures", Range(0.0001,1)) = 0.0001

	[Header(Shading Properties)]
	_SSS("Subsurface Scattering", Range(0,1)) = 0.8
	_Rs("Specular Roughness",  Range(0,1)) = 0.12
	_Gs("Glints Shininess",  Range(0.001,100)) = 2
	_T("Transmission", Range(0,1)) = 0.8
	_Rt("Transmission Roughness",  Range(0,1)) = 0.2
	_Sigma("Glints Sigma",  Range(0.000001, 1)) = 0.00001
	_Mu("Glints Mu",  Range(0, 2)) =0.5
	_scattering("Subsurface Scattering 'scattering' factor", Range(0,1)) = 0.2
	_absorption("Subsurface Scattering 'absorption' factor", Range(0,1)) = 0.8
	_a("Sigmoid a", Range(0,40)) = 3
	_b("Sigmoid b", Range(0,20)) = 2

	[Toggle] _ENABLE_DUNESRIPPLES("Enable Ripples For Dunes", Float) = 1
	[Toggle] _ENABLE_SANDDETAILS("Enable Sand Details", Float) = 1

	[Header(Debug Toggles)]
	[Toggle] _ENABLE_DIFFUSE("Enable Diffuse", Float) = 1
	[Toggle] _ENABLE_SSS("Enable Subsurface Scattering", Float) = 1
	[Toggle] _ENABLE_SPECULAR("Enable Specular", Float) = 1
	[Toggle] _ENABLE_GLINTS("Enable Glints", Float) = 1
	[Toggle] _ENABLE_FRESNEL("Enable Fresnel", Float) = 1
	[Toggle] _ENABLE_TRANSMISSION("Enable Transmission", Float) = 1
	[Toggle] _ENABLE_CLOSEONLY("Only Show Lclose", Float) = 0
	[Toggle] _ENABLE_FARONLY("Only Show Lfar", Float) = 0
	[Toggle] _ENABLE_SHOWMICRO("Show Micro Normals", Float) = 0
	[Toggle] _ENABLE_DEBUGDISTANCE("Show Sig Function Outputs", Float) = 0
	[Toggle] _ENABLE_SHOWGDF("Show Glints GDF Output", Float) = 0
	[Toggle] _ENABLE_DUNESRIPPLES("Enable Ripples For Dunes", Float) = 1
	[Toggle] _ENABLE_SANDDETAILS("Enable Sand Details", Float) = 1
	[Toggle] _ENABLE_LAMBERT("Simple Lambertian Shading", Float) = 1
	}
		SubShader{
		
		CGINCLUDE

		// Textures
		sampler2D _SlopeTex;
		sampler2D _ColorTex;
		sampler2D _GlintTex;
		sampler2D _AverageColorTex;
		sampler2D _ShallowX;
		sampler2D _SteepX;
		sampler2D _ShallowZ;
		sampler2D _SteepZ;
		float _SteepnessSharpnessPower;
		int _RipplesSteepFrequency;
		int _RipplesShallowFrequency;
		float _RipplesStrength;
		sampler2D _SandDetails;
		float _SandDetailsFrequency;
		float _DetailsStrength;

		// Texture sampling
		float _NumDims;
		float _SampleDistance;

		// Shading contributions controls
		float _NoiseScale;
		float _SSS;
		float _Rs;
		float _Gs;
		float _Rt;
		float _T;
		float _P;
		float _Sigma;
		float _Mu;
		float _scattering;
		float _absorption;
		float _a;
		float _b;

		#include "UnityCG.cginc"
		#include "AutoLight.cginc"
		#include "Lighting.cginc"
		#include "/Includes/Helpers.cginc"
		#include "/Includes/Shading.cginc"
		#include "/Includes/RandomGeneration.cginc"
		#pragma multi_compile_fwdbase
		#pragma shader_feature _RECEIVE_SHADOWS_ON
		#pragma multi_compile _ENABLE_DUNESRIPPLES_OFF _ENABLE_DUNESRIPPLES_ON
		#pragma multi_compile _ENABLE_SANDDETAILS_OFF _ENABLE_SANDDETAILS_ON 
		#pragma multi_compile  _ENABLE_VR_OFF _ENABLE_VR_ON
		#pragma multi_compile  _ENABLE_DIFFUSE_OFF _ENABLE_DIFFUSE_ON
		#pragma multi_compile  _ENABLE_SSS_OFF _ENABLE_SSS_ON
		#pragma multi_compile  _ENABLE_SPECULAR_OFF _ENABLE_SPECULAR_ON
		#pragma multi_compile _ENABLE_FRESNEL_OFF _ENABLE_FRESNEL_ON
		#pragma multi_compile _ENABLE_GLINTS_OFF _ENABLE_GLINTS_ON
		#pragma multi_compile _ENABLE_TRANSMISSION_OFF _ENABLE_TRANSMISSION_ON
		#pragma multi_compile _ENABLE_CLOSEONLY_OFF _ENABLE_CLOSEONLY_ON
		#pragma multi_compile _ENABLE_FARONLY_OFF _ENABLE_FARONLY_ON
		#pragma multi_compile _ENABLE_SHOWMICRO_OFF _ENABLE_SHOWMICRO_ON
		#pragma multi_compile _ENABLE_DEBUGDISTANCE_OFF _ENABLE_DEBUGDISTANCE_ON
		#pragma multi_compile _ENABLE_SHOWGDF_OFF _ENABLE_SHOWGDF_ON
		#pragma multi_compile _ENABLE_DUNESRIPPLES_OFF _ENABLE_DUNESRIPPLES_ON
		#pragma multi_compile _ENABLE_SANDDETAILS_OFF _ENABLE_SANDDETAILS_ON 
		#pragma multi_compile _ENABLE_LAMBERT_OFF _ENABLE_LAMBERT_ON
		#pragma target 4.0
		
		void multiSampledTextures(float2 uv, float3 n_object, float3 n_world, float4 t_world, float3 l, float3 v, out float3 slopes, out float3 colors, out float glintsControls, out float g) {
			float3 tempSlopes; float3 tempColors; float tempG; float tempGlintsControls; 
			float2 texLookup;
			float3 microLightReflectDirection;
			float dx; float dy;
			float2 scaledUV = uv * _NoiseScale;

			// Dimensions should be integers
			int numDims = _NumDims - (1 - (_NumDims % 2));

			for (int i = -floor(numDims / 2); i < floor(numDims / 2) + 1; i++) {
				for (int j = -floor(numDims / 2); j < floor(numDims / 2) + 1; j++) {
					// Find UV sample positions
					dx = _SampleDistance * i; dy = _SampleDistance * j;
					texLookup = float2(scaledUV + ddx(scaledUV) * dx + ddy(scaledUV) * dy);
					tempSlopes = NormalFromTangentTex(texLookup, _SlopeTex, n_world, t_world, 1, float3(-1,1,-1));

					tempGlintsControls = tex2D(_GlintTex, texLookup).x;

					// New light calculations
					microLightReflectDirection = normalize(reflect(-l, tempSlopes));
					tempG = saturate(pow(max(0, dot(microLightReflectDirection, v)), _Gs)) *GDF(tempGlintsControls, _Sigma, _Mu);

					// Use gaussian kernel for final result
					float gaussianKernel = GDF(i / numDims, 0.5, 0) + GDF(j / numDims, 0.5, 0);
					float divider = gaussianKernel / (pow(numDims, 2));
					slopes += tempSlopes * divider;
					glintsControls += tempGlintsControls * divider;
					g += tempG * divider;
				}
			}
			colors = tex2D(_ColorTex, scaledUV); // Colors do not need to be multi sampled
		}

		// Uses approach from Alan Zucconi: https://www.alanzucconi.com/2019/10/08/journey-sand-shader-6/
		float3 GetRipplesNormal(float2 uv, float3 n, float4 t)
		{
			float3 textureInvertion = float3(1, 1, 1);
			// get the power of xz direction
			float xzRate = atan(abs(n.z / n.x));
			float3 Y_WORLD = float3(0, 1, 0);
			float3 Z_WORLD = float3(0, 0, 1);
			float3 X_WORLD = float3(1, 0, 0);
			float zRate = abs(dot(n, Z_WORLD));
				float xRate = abs(dot(n, X_WORLD));

			// get the steepness
			float steepness = dot(n, Y_WORLD); 
			steepness = saturate(pow(steepness, _SteepnessSharpnessPower)); 

			// shallow
			float3 shallowX = NormalFromTangentTex(uv.xy * _RipplesShallowFrequency, _ShallowX, n, t, _RipplesStrength, textureInvertion);
			float3 shallowZ = NormalFromTangentTex(uv.xy * _RipplesShallowFrequency, _ShallowZ, n, t, _RipplesStrength, textureInvertion);
			float3 shallow = shallowX * shallowZ;

			// steep
			float3 steepX = NormalFromTangentTex(uv.xy * _RipplesSteepFrequency, _SteepX, n, t, _RipplesStrength, textureInvertion);
			float3 steepZ = NormalFromTangentTex(uv.xy * _RipplesSteepFrequency, _SteepZ, n, t, _RipplesStrength, textureInvertion);
			float3 steep = lerp(steepZ, steepX, xRate);

			return normalize(lerp(shallow, steep, steepness));
		} 

		float4 SandShade(float2 uv, float3 pos_object, float3 pos_world, float3 normal_object, float3 normal_world, float4 tangent_object, float4 tangent_world, float atten)
		{
			float3 camPos =  _WorldSpaceCameraPos.xyz;

			// initialize shading variables
			float3 Ld = float3(0, 0, 0);
			float3 Lf = float3(0, 0, 0);
			float3 Lg = float3(0, 0, 0);
			float3 Ls = float3(0, 0, 0);
			float3 Lt = float3(0, 0, 0);
			float3 LbrdfType = float3(0, 0, 0);
			float3 Lbrdf = float3(0, 0, 0);
			float3 Lclose = float3(0, 0, 0);
			float3 Lfar = float3(0, 0, 0);
			fixed4 Lfinal = fixed4(0, 0, 0, 1);
			float g = 0;
			float f = 0;
			float t = 0;

			// Sigma function lerp from Lclose to Lfar
			float a = _a;
			float b = _b;

			// Subsurface scattering variables
			float fs = _scattering * _SSS;
			float fe = exp(-_absorption * _SSS);

			// Distance to eye from point
			float pointDistance = length(pos_world.xyz - camPos);

			// Normal and light direction calculations
			float3 viewDirection = normalize(camPos - pos_world.xyz);
			float3 lightDirection = normalize(lerp(_WorldSpaceLightPos0.xyz, _WorldSpaceLightPos0.xyz - pos_world.xyz, _WorldSpaceLightPos0.w));
			float3 macroNormalDirection = normal_world;

			#ifdef _ENABLE_DUNESRIPPLES_ON
				macroNormalDirection = GetRipplesNormal(uv, macroNormalDirection, tangent_world);
			#endif
			#ifdef _ENABLE_SANDDETAILS_ON
				macroNormalDirection = NormalFromTangentTex(uv * _SandDetailsFrequency, _SandDetails, macroNormalDirection, tangent_world, _DetailsStrength, float3(1,1,1));
			#endif

			// Textures sampling
			float3 slopes; float3 colors; float glintsControls; float tempGlints;
			float2 texLookup = -uv;
			multiSampledTextures(texLookup, normal_object, normal_world, tangent_world, lightDirection, viewDirection, slopes, colors, glintsControls, tempGlints);

			// Normal and light calculations based on sampled textures
			float3 microNormalDirection = slopes;
			float3 microLightReflectDirection = normalize(reflect(-lightDirection, microNormalDirection));
			float3 macroLightReflectDirection = normalize(reflect(-lightDirection, macroNormalDirection));
			float3 macroViewReflectDirection = normalize(reflect(-viewDirection, macroNormalDirection));

			float cosine_theta = max(0, dot(macroNormalDirection, lightDirection));

			#ifdef _ENABLE_SHOWMICRO_ON
				return float4(microNormalDirection, 1);
			#endif 

			// Unity function for retrieving environment light
			UnityGI gi_macro = GetUnityGI(_LightColor0.rgb, lightDirection, macroNormalDirection, viewDirection, macroViewReflectDirection, atten, 1, pos_world.xyz);

			// Light colors 
			fixed shadow = atten;
			float3 lightColor = _LightColor0.rgb * shadow;
			float3 skyLight =  max(0.0, intensity(gi_macro.indirect.specular.rgb))* float3(1, 1, 1); // Only retrieve intensity and not color of environment light
			float3 rho_m = colors;
			float3 rho_n = tex2D(_AverageColorTex, float2(0,0)).rgb;
			float3 Kd_m = rho_m / PI;
			float3 Kd_n = rho_n / PI;
			float3 fresnelColor = skyLight + (lightColor * cosine_theta);
			float3 glintsColor = lightColor * 500; // Glints are multiplied by large value
			float3 transmissionColor = lightColor * rho_n;

			// GLINTS
			#ifdef _ENABLE_GLINTS_ON
				g = tempGlints; // sampled glints
				g *= cosine_theta; // only in direct light
				g *= shadow; // not if shadowed
				#ifdef _ENABLE_SHOWGDF_ON
					return float4(g, g, g, 1);
				#endif
			#endif

			// FRESNEL
			#ifdef _ENABLE_FRESNEL_ON
				float3 h = normalize(lightDirection + macroLightReflectDirection);
				float ior = 1.458; // IOR of silica
				f = F(_Rs) * Schlick(h, viewDirection, ior);
			#endif

			// DIFFUSE
			#ifdef _ENABLE_DIFFUSE_ON 

				// SUBSURFACE SCATTERING
				#ifdef _ENABLE_SSS_ON
					// Diffuse close
					Ld = Kd_m * lightColor * (fs + (1 - fs) * Lambert(lightDirection, microNormalDirection));
					Ld += Kd_m * skyLight;
					Ld *= fe;

					// Diffuse far
					Lbrdf = lightColor * Kd_n * (fs + (1 - fs) * (LambertSphere(viewDirection, lightDirection, macroNormalDirection)));
					Lbrdf += skyLight * Kd_n;
					Lbrdf *= fe;
				#endif

				#ifdef _ENABLE_SSS_OFF
					// Diffuse close
					Ld = lightColor * Kd_m * Lambert(lightDirection, microNormalDirection));
					Ld += skyLight * Kd_m;

					// Diffuse far
					Lbrdf = lightColor * Kd_n * LambertSphere(viewDirection, lightDirection, macroNormalDirection);
					Lbrdf += skyLight * Kd_n;
				#endif

				#ifdef _ENABLE_FRESNEL_ON
					Ld *= (1 - f);
					Lbrdf *= (1 - f);
				#endif

				Lclose += Ld;
				Lfar += Lbrdf;
			#endif

			// TRANSMISSION
			#ifdef _ENABLE_TRANSMISSION_ON	
				t = Transmission(macroNormalDirection, viewDirection, lightDirection, _Rt, _T);
				Lt = transmissionColor * t;

				Lclose *= Text(_T);
				Lclose += Lt;

				Lfar *= Text(_T);
				Lfar += Lt;
			#endif

			// SPECULAR
			#ifdef _ENABLE_SPECULAR_ON
				Lg = glintsColor * g;
				Lf = fresnelColor * f;
				Lclose += Lg + Lf;
				Lfar += Lf; 
			#endif


			#ifdef _ENABLE_CLOSEONLY_ON
				Lfar = Lclose;
			#endif

			#ifdef _ENABLE_FARONLY_ON
				Lclose = Lfar;
			#endif

			#ifdef _ENABLE_DEBUGDISTANCE_ON
				Lclose = float3(1, 0, 0);
				Lfar = float3(0, 0, 1);
			#endif
			
			Lfinal.rgb = max(float3(0, 0, 0), (1 - sig(pointDistance, a, b)) * Lclose + sig(pointDistance, a, b) * Lfar);

			#ifdef _ENABLE_LAMBERT_ON
				float3 lambert = Lambert(lightDirection, normal_world) * Kd_n * lightColor + Kd_n * skyLight;
				return float4(lambert, 1);
			#endif
			return float4(Lfinal.rgb, 1);
		}

		ENDCG

			Pass {
				Name "FORWARD"
				Tags {
					"LightMode" = "ForwardBase" "RenderType" = "Opaque"
				}
				
				cull off
				CGPROGRAM
		
				#pragma vertex vert
				#pragma fragment frag


		struct VertexInput {
			float4 vertex : POSITION;       
			float3 normal : NORMAL;         
			float4 tangent : TANGENT;		
			float2 texcoord0 : TEXCOORD0;   
		};

		struct VertexOutput {
			float4 pos : SV_POSITION;              
			float2 uv0 : TEXCOORD0;                
			float3 normalObject : TEXCOORD1;   
			float3 normalWorld : TEXCOORD2;    
			float4 tangentObject : TEXCOORD3;			 
			float4 tangentWorld : TEXCOORD4;			  
			float3 worldPos : TEXCOORD5;		   
			float3 objectPos : TEXCOORD6;		   
			LIGHTING_COORDS(7,8)                   
		};


		VertexOutput vert(VertexInput v) {
			 VertexOutput o = (VertexOutput)0;
			 o.uv0 = v.texcoord0;		 
			 o.objectPos = v.vertex;
			 o.pos = UnityObjectToClipPos(v.vertex);
			 o.worldPos = mul(unity_ObjectToWorld, v.vertex);
			 o.normalObject = v.normal;	
			 o.normalWorld = UnityObjectToWorldNormal(v.normal);
			 o.tangentObject = v.tangent;
			 o.tangentWorld = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);
			 TRANSFER_SHADOW(o);
			 TRANSFER_VERTEX_TO_FRAGMENT(o);
			 return o;
		}
		
		float4 frag(VertexOutput i) : COLOR
		{
			return SandShade(i.uv0, i.objectPos, i.worldPos, i.normalObject, i.normalWorld, i.tangentObject, i.tangentWorld, LIGHT_ATTENUATION(i));
		}

		ENDCG
		}
		// Pass for second light
		Pass {
				Name "FORWARDADD"
				Tags {
					"LightMode" = "ForwardAdd" "RenderType" = "Opaque"
				}

				cull off
				Blend One One // additive blending 
				CGPROGRAM

				#pragma vertex vert
				#pragma fragment frag

		struct VertexInput {
			float4 vertex : POSITION;
			float3 normal : NORMAL;
			float4 tangent : TANGENT;
			float2 texcoord0 : TEXCOORD0;
		};

		struct VertexOutput {
			float4 pos : SV_POSITION;
			float2 uv0 : TEXCOORD0;
			float3 normalObject : TEXCOORD1;
			float3 normalWorld : TEXCOORD2;
			float4 tangentObject : TEXCOORD3;
			float4 tangentWorld : TEXCOORD4;
			float3 worldPos : TEXCOORD5;
			float3 objectPos : TEXCOORD6;
			LIGHTING_COORDS(7,8)
		};


		VertexOutput vert(VertexInput v) {
			 VertexOutput o = (VertexOutput)0;
			 o.uv0 = v.texcoord0;
			 o.objectPos = v.vertex;
			 o.pos = UnityObjectToClipPos(v.vertex);
			 o.worldPos = mul(unity_ObjectToWorld, v.vertex);
			 o.normalObject = v.normal;
			 o.normalWorld = UnityObjectToWorldNormal(v.normal);
			 o.tangentObject = v.tangent;
			 o.tangentWorld = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);
			 TRANSFER_SHADOW(o);
			 TRANSFER_VERTEX_TO_FRAGMENT(o);
			 return o;
		}
				//--------------------------
				float4 frag(VertexOutput i) : COLOR
				{
					return SandShade(i.uv0, i.objectPos, i.worldPos, i.normalObject, i.normalWorld, i.tangentObject, i.tangentWorld, LIGHT_ATTENUATION(i));
				}
			ENDCG
		}
		UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"
	} Fallback "VertexLit"
}