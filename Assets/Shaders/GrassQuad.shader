// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'unity_World2Shadow' with 'unity_WorldToShadow'

Shader "Custom/GrassQuad"
{
	Properties
	{
		_MainTex ("Grass Texture", 2D) = "white" {}
		_NoiseTex ("Noise Texture", 2D) = "white" {}
		_WindTex ("Wind Map Texture", 2D) = "white" {}
		_BaseHeight ("Height of Grass", Range(0, 20)) = 0.001
		_GrassSize("Grass Size", Range(0.01, 1)) = 0.05
        _WindScale("Wind Scale", Range(0, 5)) = 0.5
		_RandomDirScale("Random Direction Scale", Range(0, 5)) = 1
		// 压倒范围
		_FallRange("Fall Range", Range(0, 20)) = 1
		_TargetPos("Target Pos", Vector) = (0,0,0,0)
	}

	CGINCLUDE
	#include "UnityCG.cginc"
	#include "Autolight.cginc"

	sampler2D _RandomMap;
	sampler2D _MainTex;
	float4 _MainTex_ST;
	sampler2D _NoiseTex;
	sampler2D _WindTex;
	float _BaseHeight;
	float _GrassSize;
	float _WindScale;
	float _RandomDirScale;
	float3 _TargetPos;
	float _FallRange;

	struct vertIn
	{
		float4 vertex : POSITION;
		float3 normal : NORMAL;
		float4 tangent : TANGENT;
		float4 uv : TEXCOORD0;
	};

	struct geomOut
	{
		float4 pos : SV_POSITION;
	#if UNITY_PASS_FORWARDBASE
		float2 uv : TEXCOORD0;
		unityShadowCoord4 _ShadowCoord : TEXCOORD2;
	#endif
	};

	float rand(float seed)
	{
		return frac(sin(seed)*10000.0);
	}

	// Simple noise function, sourced from http://answers.unity.com/answers/624136/view.html
	// Extended discussion on this function can be found at the following link:
	// https://forum.unity.com/threads/am-i-over-complicating-this-random-function.454887/#post-2949326
	// Returns a number in the 0...1 range.
	float rand(float3 seed)
    {
        return frac(sin(dot(seed.xyz, float3(12.9898, 78.233, 53.539))) * 43758.5453);
    }

	vertIn vert (vertIn v)
	{
		v.vertex = v.vertex + float4(rand(v.vertex.xyz) - 0.5, rand(v.vertex.xyz * 2) - 0.5, 0, 0);
		return v;
	}

	geomOut GeneratePos(float3 pos, float2 uv)
	{
		geomOut o;
		o.pos = UnityObjectToClipPos(pos);

	#if UNITY_PASS_FORWARDBASE
		o.uv = uv;
		o._ShadowCoord = ComputeScreenPos(o.pos);
	#elif UNITY_PASS_SHADOWCASTER
		//o.pos = fixed4(pos, 0);
		o.pos = UnityApplyLinearShadowBias(o.pos);
	#endif

		return o;
	}

	// 输入的是点，输出的是三角形
	// maxvertexcount 控制输出的点的数量
	[maxvertexcount(6)]
	void geom(point vertIn p[1], inout TriangleStream<geomOut> triStream)
	{
		// 采样噪音图作为风场
		float2 wind = (-tex2Dlod(_WindTex, float4(p[0].uv.x + _Time.x * 2 , p[0].uv.y, 0, 0)) + fixed2(0.5, 0.5)) * 8;
		float3 windVec = float3(wind.x, 0, wind.y);

		// 定义【世界坐标系】下的向上的单位向量
		float3 up = float3(0, 1, 0);

		// 采样噪声图备用
		float4 sampleNoise = tex2Dlod(_NoiseTex, float4(p[0].uv.x, p[0].uv.y, 0, 0));
		
		// 随机生长方向
		float3 randomDir = float3(rand(p[0].vertex.x + sampleNoise.x) - 0.5, 0, rand(p[0].vertex.z + sampleNoise.y) - 0.5);

		// 采样噪音图 随机顶点高度 
		float height = _BaseHeight + 10 * sampleNoise.y;

		// 和移动物体交互
		// 计算和物体的距离
		float dis = distance(_TargetPos, p[0].vertex);
		float fall = smoothstep(_FallRange * 0.5, _FallRange, dis);

		// 校正后的方向
		float3 dir = normalize((height * up + windVec * _WindScale + 
			randomDir * _RandomDirScale) * fall + (p[0].vertex - _TargetPos) * float3(1,0,1) * (1 - fall));
		// 随机+风影响后的顶点
		float3 Pt = p[0].vertex + height * dir;

		// 中间点
		float3 mid = (Pt - p[0].vertex) * 0.4 + p[0].vertex;

		// 拿到摄像机的观察向量，用来做Billboard
		float3 look = _WorldSpaceCameraPos - mul(unity_ObjectToWorld, p[0].vertex);

		// 求两边的点
		float3 crossDir = normalize(cross(Pt - p[0].vertex, look));
		float3 pos1 = mid + crossDir * _GrassSize;// + windVec * 0.35;
		float3 pos2 = mid - crossDir * _GrassSize;// + windVec * 0.35;

		// UV
		float2 grassBottom = float2(0, 0);
		float2 grassMidUv = float2(randomDir.x, 0.4);
		float2 grassTopUv = float2(randomDir.x, 0.79);

		// 添加三角形
		// 草 下部三角形
		triStream.Append(GeneratePos(p[0].vertex, grassBottom));
		triStream.Append(GeneratePos(pos1, grassMidUv));
		triStream.Append(GeneratePos(pos2, grassMidUv));
		triStream.RestartStrip();

		// 草 上部三角形
		triStream.Append(GeneratePos(pos1, grassMidUv));
		triStream.Append(GeneratePos(pos2, grassMidUv));
		triStream.Append(GeneratePos(Pt, grassTopUv));
		triStream.RestartStrip();
	}

	ENDCG

	SubShader
	{
		Cull Off

		Pass
		{
			Tags
			{ 
				"RenderType" = "Opaque" 
				"LightMode" = "ForwardBase" 
			}
			
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma geometry geom
			#pragma target 4.6
			#pragma multi_compile_fwdbase
			
			#include "Lighting.cginc"  

			fixed4 frag (geomOut i) : SV_Target
			{
				//使用内置宏计算阴影值
				fixed shadow = max(SHADOW_ATTENUATION(i), 0.5);
				fixed4 col = tex2D(_MainTex, i.uv) * fixed4(shadow, shadow, shadow, 1);
				return col;
			}

			ENDCG
		}

		Pass
		{
			Tags { "LightMode" = "ShadowCaster"}

			CGPROGRAM
			#pragma target 4.6
			#pragma vertex vert
			#pragma geometry geom
			#pragma fragment frag
			//#pragma hull hull
			//#pragma domain domain
			#pragma multi_compile_shadowcaster

			float4 frag(geomOut i) : SV_Target
			{
				SHADOW_CASTER_FRAGMENT(i)
			}

			ENDCG
		}
	}
}
