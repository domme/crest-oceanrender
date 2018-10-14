Shader "WaveParticles/FBMDisplacement"
{
	Properties
	{
    _NumOctaves("NumOctaves", int) = 4
    _Amplitude("Amplitude", float) = 10.0
    _FlowDir("FlowDir", Vector) = (1,1,0,0)
    _FlowSpeeds("FlowSpeeds", Vector) = (0.25, 0.5, 0.75, 1.0)
    _AmplitudeMods("AmplitudeMods", Vector) = (1,1,1,1)
    _Freqs("Freqs", Vector) = (1,1,1,1)
    _NoiseTex("Noise Texture", 2D) = "white" {}
    _CuspSize("CuspSize", float) = 2
    _Choppiness("Choppiness", Vector) = (1,1,0,0)
    _CuspFreq("CuspFreq", Vector) = (1,1,1,1)
  }

	Category
	{
		Tags { "Queue"="Geometry" }

		SubShader
		{
			Pass
			{
				Name "BASE"
				Tags { "LightMode" = "Always" }
				Blend One One
			
				CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag
				#pragma multi_compile_fog
        #pragma multi_compile_instancing
				#include "UnityCG.cginc"

        struct appdata_t {
          float4 vertex : POSITION;
          float2 texcoord : TEXCOORD0;
        };

        struct v2f {
          float4 vertex : SV_POSITION;
          float3 worldPos : TEXCOORD0;
        };

        uniform int _NumOctaves;
        uniform float _Amplitude;
        
        uniform float4 _FlowDir;
        uniform float4 _FlowSpeeds;
        uniform float4 _AmplitudeMods;
        uniform float4 _Freqs;

        uniform float _CuspSize;
        uniform float4 _Choppiness;
        uniform float4 _CuspFreq;

        uniform sampler2D _NoiseTex;
        uniform float4 _NoiseTex_ST;

				v2f vert( appdata_t v )
				{
          v2f o;
          o.vertex = UnityObjectToClipPos(v.vertex);
          o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

					return o;
				}

        float3 SampleWpGrid(sampler2D gridTex, float2 baseUv, float2 flowDir, float fTime)
        {
          float2 uv = baseUv + fTime * flowDir;
          float3 val = tex2Dlod(gridTex, float4(uv, 0, 0)).xyz;
          return val;
        }

        float2 Rot(float2 vec, float deg)
        {
          float2x2 rotMat = float2x2(cos(deg), - sin(deg), sin(deg), cos(deg));
          return mul(vec, rotMat);
        }

				float4 frag (v2f input) : SV_Target
				{
          float interval = 5.0;
          float timeInt = _Time.x / (2.0 * interval);
          float2 fTime = frac(float2(timeInt, timeInt * 0.5));

          float3 wpGridDispA = float3(0,0,0);
          float3 wpGridDispB = float3(0,0,0);

          float2 uv = input.worldPos.xz / 512;

          const float PI = 3.14159265;

          float amp = _Amplitude;
          for (int i = 0; i < min(_NumOctaves, 4); ++i)
          {
            float2 noiseSampleUv = uv * _Freqs[i];

            // float cuspSize = _CuspSize / _Freqs[i];
            // float2 cuspPos = int2((input.worldPos.xz / cuspSize)) * cuspSize + sign(int2(input.worldPos.xz / cuspSize)) * 0.5 * cuspSize;
            // float2 offset = cuspPos - input.worldPos.xz;

            float amplitude = amp * _AmplitudeMods[i];
            float3 noise0 = SampleWpGrid(_NoiseTex, noiseSampleUv, float2(0,0), fTime.x).xyz;

            float2 flow = _FlowDir * _FlowSpeeds[i];
            float3 noise = SampleWpGrid(_NoiseTex, noiseSampleUv, flow, fTime.x).xyz * 0.5;
            float choppiness = -_Choppiness[i] * noise.y;
            wpGridDispA += noise * float3(choppiness, amplitude, choppiness);

            flow = Rot(flow, PI * 0.5) * 2.0;
            noise = SampleWpGrid(_NoiseTex, noiseSampleUv, flow, fTime.x).xyz * 0.2;
            choppiness = -_Choppiness[i] * noise.y;
            wpGridDispA += noise * float3(choppiness, amplitude, choppiness);

            flow = Rot(flow, PI * 0.5);
            noise = SampleWpGrid(_NoiseTex, noiseSampleUv, flow, fTime.x).xyz * 0.2;
            wpGridDispA += noise * float3(choppiness, amplitude, choppiness);
            
            //wpGridDispA.xz = float2(0,0);

            // float2 hor = float3(0,0,0);
            // flow = Rot(flow, PI * 0.5);
            // hor += flow * sin(_Time.y * noise0.x * _CuspFreq[i]);
            // flow = Rot(flow, PI * 0.5);
            // hor += flow * sin(_Time.y * noise0.z * _CuspFreq[i]);
            // wpGridDispA.xz += (noise0.xz * 1.0 - 1.0) * hor * _Choppiness[i] * 0.001;

            // h = SampleWpGrid(_NoiseTex, noiseSampleUv, _FlowDir * _FlowSpeeds[i], fTime.y).x * amplitude;
            // wpGridDispB.y += h;
            // wpGridDispB.xz += normalize(offset) * _Choppiness * sin(_Time.y * 2 * _FlowSpeeds[i] * h0);
          }

          float3 disp = wpGridDispA; 
          // float3 disp = lerp(wpGridDispA, wpGridDispB, abs((2 * frac(timeInt) - 1)));

          return float4(disp, 1);
				}

				ENDCG
			}
		}
	}
}
