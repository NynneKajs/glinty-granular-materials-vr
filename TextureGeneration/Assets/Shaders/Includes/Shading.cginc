// Schlick 1994 (https://onlinelibrary.wiley.com/doi/10.1111/1467-8659.1330233)
float Schlick(float3 h, float3 v, float ior) {
	float f0 = pow(ior - 1, 2) / pow(ior + 1, 2);
	float F = f0 + (1 - f0) * pow(1 - abs((dot(v, h))), 4);
	return F;
}

// Pharr et al. 2018 (https://www.pbr-book.org/3ed-2018/Reflection_Models/Microfacet_Models)
float Cos2Theta(float3 w) { return w.z * w.z; }
float AbsCosTheta(float3 w) { return abs(w.z); }
float Sin2Theta(float3 w) {
	return max(0.0, 1.0 - Cos2Theta(w));
}
float SinTheta(float3 w) {
	return sqrt(Sin2Theta(w));
}
float CosPhi(float3 w) {
	float sinTheta = SinTheta(w);
	float result = 0;
	if (sinTheta == 0) {
		result = 1;
	}
	else {
		result = clamp(w.x / sinTheta, -1, 1);
	}
	return result;
}
float SinPhi(float3 w) {
	float sinTheta = SinTheta(w);
	float result = 0;
	if (sinTheta == 0) {
		result = 0;
	}
	else {
		result = clamp(w.y / sinTheta, -1, 1);
	}
	return result;
}
float OrenNayar(float3 l, float3 v, float3 n, float sigma) {
	float sigma2 = sigma * sigma;
	float A = 1.f - (sigma2 / (2.f * (sigma2 + 0.33f)));
	float B = 0.45f * sigma2 / (sigma2 + 0.09f);
	float sinThetaI = SinTheta(l);
	float sinThetaO = SinTheta(v);
	float sinAlpha = 0;
	float tanBeta = 0;
	float maxCos = 0;
	// << Compute cosine term of Oren–Nayar model>>
	if (sinThetaI > 0.0001 && sinThetaO > 0.0001) {
		float sinPhiI = SinPhi(l);
		float cosPhiI = CosPhi(l);
		float sinPhiO = SinPhi(v);
		float cosPhiO = CosPhi(v);
		float dCos = cosPhiI * cosPhiO + sinPhiI * sinPhiO;
		maxCos = max(0.0, dCos);
	}
	// <<Compute sine and tangent terms of Oren–Nayar model >>
	if (AbsCosTheta(l) > AbsCosTheta(v)) {
		sinAlpha = sinThetaO;
		tanBeta = saturate(sinThetaI / AbsCosTheta(l));
	}
	else {
		sinAlpha = sinThetaI;
		tanBeta = saturate(sinThetaO / AbsCosTheta(v));
	}

	return (A + B * maxCos * sinAlpha * tanBeta);
}

// D'Eon 2021 (https://arxiv.org/abs/2103.01618)
// and AndrewHelmer (https://www.shadertoy.com/view/ftlXWl)
#define K 0.142857142857 //1/7
#define Ko 0.428571428571 //3/7
float safeacos(float x) {
	return acos(clamp(x, -1.0, 1.0));
}
float phase(float u) {
	return (2.0 * (sqrt(1.0 - u * u) - u * acos(u))) / (3.0 * PI * PI);
}
float3 adjustExposureGamma(float3 col) {
	float whitePoint = 1.0;
	col /= whitePoint;
	col = float3(pow(col.x, 1.0 / 2.2), pow(col.y, 1.0 / 2.2), pow(col.z, 1.0 / 2.2));
	return col;
}

float3 Lambert(float3 l, float3 n)
{
	float cos_theta = max(0, dot(l, n));
	return float3(cos_theta, cos_theta, cos_theta);
}

float3 LambertSphere(float3 wo, float3 wi, float3 norm) {
	float3 c = float3(1, 1, 1);
	float3 kd = c;
	float uo = max(0, dot(wo, norm));
	float ui = max(0, dot(wi, norm));

	float uo2 = uo * uo;
	float ui2 = ui * ui;
	float S = sqrt((1.0 - uo2) * (1.0 - ui2));
	float cp = -((-dot(wo, wi) + uo * ui) / S);
	float phi = safeacos(cp);
	float iodot = dot(wo, wi);

	float3 SS = c * (phase(-iodot) / (uo + ui));

	float3 fr = float3(
		SS.x + 0.234459 * pow(kd.x, 1.85432) + (0.0151829 * (c.x - 0.24998) * (abs(phi) + sqrt(ui * uo))) / (0.113706 + (safeacos(S) / S)),
		SS.y + 0.234459 * pow(kd.y, 1.85432) + (0.0151829 * (c.x - 0.24998) * (abs(phi) + sqrt(ui * uo))) / (0.113706 + (safeacos(S) / S)),
		SS.z + 0.234459 * pow(kd.z, 1.85432) + (0.0151829 * (c.x - 0.24998) * (abs(phi) + sqrt(ui * uo))) / (0.113706 + (safeacos(S) / S)));
	fr = float3(max(0, fr.x), max(0, fr.y), max(0, fr.z));

	return (float3(saturate(PI * ui * fr.x), saturate(PI * ui * fr.y), saturate(PI * ui * fr.z)));
}

// Fresnel roughness
float F(float specularRoughness) {
	return saturate(-20.80 * pow(specularRoughness, 5) + 60 * pow(specularRoughness, 4) - 55.9 * pow(specularRoughness, 3) + 14.55 * pow(specularRoughness, 2) + 2 * specularRoughness + 0.25)*0.4;
}
// Glints roughness
float G(float specularRoughness) {
	return saturate(1 / (1 + exp(13.5 * (specularRoughness - 0.4))));
}
// Diffuse extinction due to transmission
float Text(float transmissiveness) {
	return saturate(-3.2 * pow(transmissiveness, 4) + 4.8 * pow(transmissiveness, 3) - 2.2 * pow(transmissiveness, 2) - 0.3 * transmissiveness + 1);
}
// Custom transmission function
float3 Transmission(float3 n, float3 v, float3 l, float transRoughness, float transmissiveness) {
	float Rt = 0.2 + transRoughness * (0.4 - 0.2); // scale Rt to values min = 0.2, max = 0.4
	float t = 1 - max(0, dot(n, v)); // Only consider normals pointing not straight at viewer 																								   
	t = pow(t, 1 / Rt); // Use Phong approach to shininess
	t *= max(0, dot(l, -v)); // Only when viewer is looking torward light 
	t *= transmissiveness; // Strength multiplier 
	t *= (1 - 0.9 * transRoughness); // Decrease strength as roughness increases
	return saturate(t);
}

// Unity ambient light
UnityGI GetUnityGI(float3 lightColor, float3 lightDirection, float3 normalDirection, float3 viewDirection, float3 viewReflectDirection, float attenuation, float roughness, float3 worldPos) {
	UnityLight light;
	light.color = lightColor;
	light.dir = lightDirection;
	light.ndotl = max(0.0h, dot(normalDirection, lightDirection));
	UnityGIInput d;
	d.light = light;
	d.worldPos = worldPos;
	d.worldViewDir = viewDirection;
	d.atten = attenuation;
	d.ambient = 0.0h;
	d.boxMax[0] = unity_SpecCube0_BoxMax;
	d.boxMin[0] = unity_SpecCube0_BoxMin;
	d.probePosition[0] = unity_SpecCube0_ProbePosition;
	d.probeHDR[0] = unity_SpecCube0_HDR;
	d.boxMax[1] = unity_SpecCube1_BoxMax;
	d.boxMin[1] = unity_SpecCube1_BoxMin;
	d.probePosition[1] = unity_SpecCube1_ProbePosition;
	d.probeHDR[1] = unity_SpecCube1_HDR;
	Unity_GlossyEnvironmentData ugls_en_data;
	ugls_en_data.roughness = roughness;
	ugls_en_data.reflUVW = viewReflectDirection;
	UnityGI gi = UnityGlobalIllumination(d, 1.0h, normalDirection, ugls_en_data);
	return gi;
}

