// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "Unity Shaders Book/Chapter 6/DiffuseVertexLevel"
{
	Properties{
		_Diffuse("Diffuse", Color) = (1,1,1,1)
        _Floors("Floors", int) = 4
	}

	SubShader{
		Pass{
			Tags{
				"LightMode" = "ForwardBase"
			}

			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag
			
			#include "Lighting.cginc"

			fixed4 _Diffuse;
            int _Floors;

			struct a2v{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};

			struct v2f{
				float4 pos : SV_POSITION;
				fixed3 worldNormal : TEXCOORD0;
			};

			v2f vert(a2v v){
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = mul(v.normal, (float3x3)unity_WorldToObject);
				return o;
			}

			fixed4 frag(v2f i) : SV_TARGET{
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
				
				fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz);
                float lightStrength = saturate(dot(worldNormal, worldLight));
                //将光线强度阶梯化
                float flooredLightStrenth = (float)(((int)(lightStrength*_Floors)))/_Floors+0.1;

				fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * flooredLightStrenth;

				fixed3 color = ambient + diffuse;

				return fixed4(color, 1);
			}

			ENDCG
		}
	}
}
