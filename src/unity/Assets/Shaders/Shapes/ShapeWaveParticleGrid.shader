Shader "Ocean/Shape/Wave Particle Grid"
{
	Properties
	{
    _WpGridTex1("Wave Particle Grid 1", 2D) = "" {}
    _WpGridTex2("Wave Particle Grid 2", 2D) = "" {}
    _WpGridTex3("Wave Particle Grid 3", 2D) = "" {}
    _WpGridTex4("Wave Particle Grid 4", 2D) = "" {}
    _BaseGridSize ("Base Grid Size", float) = 32.0
    _NumGrids("NumGrids", float) = 3.0
    _GridDebug("GridDebug", int) = 0
    _FlowDir("FlowDir", Vector) = (1,1,0,0)
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

        uniform float _BaseGridSize;

        uniform sampler2D _WpGridTex1;
        uniform float4 _WpGridTex1_ST;

        uniform sampler2D _WpGridTex2;
        uniform float4 _WpGridTex2_ST;

        uniform sampler2D _WpGridTex3;
        uniform float4 _WpGridTex3_ST;

        uniform sampler2D _WpGridTex4;
        uniform float4 _WpGridTex4_ST;

        uniform float _NumGrids;
        uniform int _GridDebug;

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
          return tex2D(gridTex, uv).xyz;
        }

				float4 frag (v2f input) : SV_Target
				{
          float2 baseUv = input.worldPos.xz / _BaseGridSize;
          
          float interval = 1.0;
          float timeInt = _Time.x / (2.0 * interval);
          float2 fTime = frac(float2(timeInt, timeInt * 0.5));

          float3 wpGridDispA[4];
          wpGridDispA[0] = SampleWpGrid(_WpGridTex1, baseUv * _WpGridTex1_ST.xy, _FlowDir, fTime.x);
          wpGridDispA[1] = SampleWpGrid(_WpGridTex2, baseUv * _WpGridTex2_ST.xy, _FlowDir, fTime.x);
          wpGridDispA[2] = SampleWpGrid(_WpGridTex3, baseUv * _WpGridTex3_ST.xy, _FlowDir, fTime.x);
          wpGridDispA[3] = SampleWpGrid(_WpGridTex4, baseUv * _WpGridTex4_ST.xy, _FlowDir, fTime.x);

          float3 wpGridDispB[4];
          wpGridDispB[0] = SampleWpGrid(_WpGridTex1, baseUv * _WpGridTex1_ST.xy, _FlowDir, fTime.y);
          wpGridDispB[1] = SampleWpGrid(_WpGridTex2, baseUv * _WpGridTex2_ST.xy, _FlowDir, fTime.y);
          wpGridDispB[2] = SampleWpGrid(_WpGridTex3, baseUv * _WpGridTex3_ST.xy, _FlowDir, fTime.y);
          wpGridDispB[3] = SampleWpGrid(_WpGridTex4, baseUv * _WpGridTex4_ST.xy, _FlowDir, fTime.y);

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
