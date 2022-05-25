// General helper functions

#define	PI 3.14159265359f

float sqr(float x) {
	return x * x;
}
float length(float3 v) {
	return sqrt(sqr(v.x) + sqr(v.y) + sqr(v.z));
}
float length(float4 v) {
	return sqrt(sqr(v.x) + sqr(v.y) + sqr(v.z) + sqr(v.w));
}
float angle(float3 a, float3 b) {
	return acos(dot(a, b) / (length(a) * length(b)));
}
float step(float a, float b) {
	if (a > b) return 1;
	else return 0;
}
float fract(float x) {
	return x - floor(x);
}

float intensity(float3 val) {
	return (abs(val.x) + abs(val.y) + abs(val.z)) / 3;
}

float3 modulo(float3 divident, float3 divisor) {
	float3 positiveDivident = divident % divisor + divisor;
	return positiveDivident % divisor;
}

// Sigmoid
float sig(float x, float a, float b) {
	return 1 / (1 + exp(-a * (x - b)));
}

// Glints Gaussian Distribution
float GDF(float x, float sigma, float mu) {
	return max(0, exp(-pow(x - mu, 2) / (2 * pow(sigma, 2))));
}

// v_coda, 2018 (https://www.shadertoy.com/view/MlyBWK)
float smootherstep(float edge0, float edge1, float x)
{
	x = clamp((x - edge0) / (edge1 - edge0), 0., 1.);
	return x * x * x * (x * (x * 6. - 15.) + 10.);
}

// Based on approach by Jasper Flick (https://catlikecoding.com/unity/tutorials/rendering/part-6/Rendering-6.pdf)
float3 NormalFromTangentTex(float2 uv, sampler2D tex, float3 n, float4 t, float3 b, float strength, float3 invert)
{
	float3 textureNormal = UnpackNormal(tex2D(tex, uv));
	textureNormal = textureNormal.xzy;
	textureNormal *= invert;
	textureNormal = normalize(
		textureNormal.x * t +
		textureNormal.y * n +
		textureNormal.z * b
	);
	textureNormal = normalize(textureNormal * strength + n * (1 - strength));
	return textureNormal;
}
