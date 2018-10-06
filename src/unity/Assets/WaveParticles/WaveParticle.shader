// This file is subject to the MIT License as seen in the root of this folder structure (LICENSE)

Shader "WaveParticles/Wave Particle"
{
	Properties
	{
		_Amplitude( "Amplitude", float ) = 1
    _Choppiness("Choppiness", float) = 1.0
	}

	Category
	{
		Tags { "Queue"="Transparent" "DisableBatching" = "True" }

		SubShader
		{
			Pass
			{
				Name "BASE"
				Tags { "LightMode" = "Always" }
        ZWrite Off
				Blend One One
			
				CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag
				#pragma multi_compile_fog
        #pragma multi_compile_instancing
				#include "UnityCG.cginc"

				struct appdata_t {
					float4 vertex : POSITION;
          UNITY_VERTEX_INPUT_INSTANCE_ID
				};

				struct v2f {
					float4 vertex : SV_POSITION;
          float2 offsetXZ : TEXCCORD0;
				};

        uniform float _Amplitude;
        uniform float _Choppiness;
        
				v2f vert( appdata_t v )
				{
					v2f o;

          o.offsetXZ = v.vertex.xy * 2.0;  // -1..1

          UNITY_SETUP_INSTANCE_ID(v);

					o.vertex = UnityObjectToClipPos( float4(v.vertex.xyz, 1.0) );

					return o;
				}

				float4 frag (v2f i) : SV_Target
				{
					float4 disp = float4(0,0,0,0);
          
					if( dot(i.offsetXZ, i.offsetXZ) < 1.0 )
					{
            float2 r_signed = i.offsetXZ;
            float r = length(r_signed);
            
            const float PI = 3.14159265;
            r *= PI;

            disp.y = 0.5 * (cos(r) + 1) * _Amplitude;
            disp.xz = normalize(i.offsetXZ) * (- _Choppiness * sin(r)) * (disp.y / _Amplitude);
            
            disp.w = 1.0;
					}

					return disp / 100.0;
				}

				ENDCG
			}
		}
	}
}
