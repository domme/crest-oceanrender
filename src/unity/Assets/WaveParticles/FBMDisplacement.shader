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
          return tex2Dlod(gridTex, float4(uv, 0, 0)).xyz;
        }

				float4 frag (v2f input) : SV_Target
				{
          float interval = 5.0;
          float timeInt = _Time.x / (2.0 * interval);
          float2 fTime = frac(float2(timeInt, timeInt * 0.5));

          float3 wpGridDispA = float3(0,0,0);
          float3 wpGridDispB = float3(0,0,0);

          float2 uv = input.worldPos.xz / 512;

          float amp = _Amplitude;
          for (int i = 0; i < min(_NumOctaves, 4); ++i)
          {
            float freq = _Freqs[i];
            wpGridDispA += (amp + _AmplitudeMods[i]) * float3(0.1, 1, 0.1) * ( 
              SampleWpGrid(_NoiseTex, uv * freq, _FlowDir * _FlowSpeeds[i], fTime.x) * 0.5 +
              SampleWpGrid(_NoiseTex, uv * freq, float2(-_FlowDir.y,-_FlowDir.x) * _FlowSpeeds[i], fTime.x) * 0.5
              //SampleWpGrid(_NoiseTex, uv * freq, float2(_FlowDir.y,-_FlowDir.x) * _FlowSpeeds[min(3,i)], fTime.x) * 0.33
              );

            wpGridDispB += (amp + _AmplitudeMods[i]) * float3(0.1, 1, 0.1) * ( 
              SampleWpGrid(_NoiseTex, uv * freq, _FlowDir * _FlowSpeeds[i], fTime.y) * 0.5 + 
              SampleWpGrid(_NoiseTex, uv * freq, float2(-_FlowDir.y,-_FlowDir.x) * _FlowSpeeds[i], fTime.y) * 0.5
              //SampleWpGrid(_NoiseTex, uv * freq, float2(_FlowDir.y,-_FlowDir.x) * _FlowSpeeds[min(3,i)], fTime.y) * 0.33
              );

            //wpGridDispA += amp * float3(0.1, 1, 0.1) * ( SampleWpGrid(_NoiseTex, uv * freq, _FlowDir * _FlowSpeeds[min(3,i)], fTime.x) + SampleWpGrid(_NoiseTex, uv * freq, float2(-_FlowDir.y, _FlowDir.x) * 2 * _FlowSpeeds[min(3,i)], fTime.x));
            //wpGridDispB += amp * float3(0.1, 1, 0.1) * ( SampleWpGrid(_NoiseTex, uv * freq, _FlowDir * _FlowSpeeds[min(3,i)], fTime.y) + SampleWpGrid(_NoiseTex, uv * freq, float2(-_FlowDir.y, _FlowDir.x) * 2 * _FlowSpeeds[min(3,i)], fTime.y));
          }
                    
          float3 disp = lerp(wpGridDispA, wpGridDispB, abs((2 * frac(timeInt) - 1)));

          return float4(disp, 1);
				}

				ENDCG
			}
		}
	}
}
