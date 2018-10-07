Shader "WaveParticles/WpCombineGrids"
{
	Properties
	{
    _NumGrids("NumGrids", float) = 3.0
    _GridDebug("GridDebug", int) = 0
    _FlowDir("FlowDir", Vector) = (1,1,0,0)
    _TwoScales("TwoScales", int) = 0
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

        uniform sampler2D_float _WpGridTex1;
        uniform float4 _WpGridTex1_ST;

        uniform sampler2D_float _WpGridTex2;
        uniform float4 _WpGridTex2_ST;

        uniform sampler2D_float _WpGridTex3;
        uniform float4 _WpGridTex3_ST;

        uniform sampler2D_float _WpGridTex4;
        uniform float4 _WpGridTex4_ST;

        uniform float _strength[4];
        uniform float _flowSpeeds[4];

        uniform float _NumGrids;
        uniform int _GridDebug;

        uniform bool _TwoScales;

        uniform float4 _FlowDir;

				v2f vert( appdata_t v )
				{
          v2f o;
          o.vertex = UnityObjectToClipPos(v.vertex);
          o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

					return o;
				}

        float3 SampleWpGrid(sampler2D gridTex, float2 baseUv, float2 flowDir, float fTime)
        {
          float2 uv = baseUv - (flowDir / 2) * fTime * flowDir;
          return tex2Dlod(gridTex, float4(uv, 0, 0)).xyz;
        }

				float4 frag (v2f input) : SV_Target
				{
          float2 baseUv = input.worldPos.xz / 32.0;
          
          float interval = 1.0;
          float timeInt = _Time.x / (2.0 * interval);
          float2 fTime = frac(float2(timeInt, timeInt * 0.5));

          float3 wpGridDispA[4];
          float3 wpGridDispB[4];

          if (_TwoScales)
          {
              float scaleMain = 1;
              float scaleDetail = 1;

              wpGridDispA[0] = _strength[0] * scaleMain * SampleWpGrid(_WpGridTex1, baseUv * _WpGridTex1_ST.xy, _FlowDir * _flowSpeeds[0], fTime.x);
              wpGridDispA[1] = _strength[1] * scaleMain * SampleWpGrid(_WpGridTex2, baseUv * _WpGridTex2_ST.xy, _FlowDir * _flowSpeeds[1], fTime.x);
              wpGridDispA[2] = _strength[2] * scaleMain * SampleWpGrid(_WpGridTex3, baseUv * _WpGridTex3_ST.xy, _FlowDir * _flowSpeeds[2], fTime.x);
              wpGridDispA[3] = _strength[3] * scaleMain * SampleWpGrid(_WpGridTex4, baseUv * _WpGridTex4_ST.xy, _FlowDir * _flowSpeeds[3], fTime.x);

              wpGridDispA[0] += _strength[0] * scaleDetail * SampleWpGrid(_WpGridTex1, baseUv * _WpGridTex1_ST.xy * 2.0, _FlowDir * _flowSpeeds[0], fTime.x);
              wpGridDispA[1] += _strength[1] * scaleDetail * SampleWpGrid(_WpGridTex2, baseUv * _WpGridTex2_ST.xy * 2.0, _FlowDir * _flowSpeeds[1], fTime.x);
              wpGridDispA[2] += _strength[2] * scaleDetail * SampleWpGrid(_WpGridTex3, baseUv * _WpGridTex3_ST.xy * 2.0, _FlowDir * _flowSpeeds[2], fTime.x);
              wpGridDispA[3] += _strength[3] * scaleDetail * SampleWpGrid(_WpGridTex4, baseUv * _WpGridTex4_ST.xy * 2.0, _FlowDir * _flowSpeeds[3], fTime.x);

              wpGridDispB[0] = _strength[0] * scaleMain * SampleWpGrid(_WpGridTex1, baseUv * _WpGridTex1_ST.xy, _FlowDir * _flowSpeeds[0], fTime.y);
              wpGridDispB[1] = _strength[1] * scaleMain * SampleWpGrid(_WpGridTex2, baseUv * _WpGridTex2_ST.xy, _FlowDir * _flowSpeeds[1], fTime.y);
              wpGridDispB[2] = _strength[2] * scaleMain * SampleWpGrid(_WpGridTex3, baseUv * _WpGridTex3_ST.xy, _FlowDir * _flowSpeeds[2], fTime.y);
              wpGridDispB[3] = _strength[3] * scaleMain * SampleWpGrid(_WpGridTex4, baseUv * _WpGridTex4_ST.xy, _FlowDir * _flowSpeeds[3], fTime.y);

              wpGridDispB[0] += _strength[0] * scaleDetail * SampleWpGrid(_WpGridTex1, baseUv * _WpGridTex1_ST.xy * 2.0, _FlowDir * _flowSpeeds[0], fTime.y);
              wpGridDispB[1] += _strength[1] * scaleDetail * SampleWpGrid(_WpGridTex2, baseUv * _WpGridTex2_ST.xy * 2.0, _FlowDir * _flowSpeeds[1], fTime.y);
              wpGridDispB[2] += _strength[2] * scaleDetail * SampleWpGrid(_WpGridTex3, baseUv * _WpGridTex3_ST.xy * 2.0, _FlowDir * _flowSpeeds[2], fTime.y);
              wpGridDispB[3] += _strength[3] * scaleDetail * SampleWpGrid(_WpGridTex4, baseUv * _WpGridTex4_ST.xy * 2.0, _FlowDir * _flowSpeeds[3], fTime.y);
          }
          else
          {
              wpGridDispA[0] = _strength[0] * SampleWpGrid(_WpGridTex1, baseUv * _WpGridTex1_ST.xy, _FlowDir * _flowSpeeds[0], fTime.x);
              wpGridDispA[1] = _strength[1] * SampleWpGrid(_WpGridTex2, baseUv * _WpGridTex2_ST.xy, _FlowDir * _flowSpeeds[1], fTime.x);
              wpGridDispA[2] = _strength[2] * SampleWpGrid(_WpGridTex3, baseUv * _WpGridTex3_ST.xy, _FlowDir * _flowSpeeds[2], fTime.x);
              wpGridDispA[3] = _strength[3] * SampleWpGrid(_WpGridTex4, baseUv * _WpGridTex4_ST.xy, _FlowDir * _flowSpeeds[3], fTime.x);

              wpGridDispB[0] = _strength[0] * SampleWpGrid(_WpGridTex1, baseUv * _WpGridTex1_ST.xy, _FlowDir * _flowSpeeds[0], fTime.y);
              wpGridDispB[1] = _strength[1] * SampleWpGrid(_WpGridTex2, baseUv * _WpGridTex2_ST.xy, _FlowDir * _flowSpeeds[1], fTime.y);
              wpGridDispB[2] = _strength[2] * SampleWpGrid(_WpGridTex3, baseUv * _WpGridTex3_ST.xy, _FlowDir * _flowSpeeds[2], fTime.y);
              wpGridDispB[3] = _strength[3] * SampleWpGrid(_WpGridTex4, baseUv * _WpGridTex4_ST.xy, _FlowDir * _flowSpeeds[3], fTime.y);
          }
          
          int numGrids = (int)clamp(_NumGrids, 0.0, 4.0);

          float3 dispA = float3(0, 0, 0);
          float3 dispB = float3(0, 0, 0);
          for (int i = 0; i < numGrids; ++i)
          {
            dispA += wpGridDispA[i];
            dispB += wpGridDispB[i];
          }

          if (_GridDebug > 0)
          {
            dispA = wpGridDispA[clamp(_GridDebug - 1, 0, 3)];
            dispB = wpGridDispB[clamp(_GridDebug - 1, 0, 3)];
          }
          
          float3 disp = lerp(dispA, dispB, abs((2 * frac(timeInt) - 1)));

          return float4(disp, 1);
				}

				ENDCG
			}
		}
	}
}
