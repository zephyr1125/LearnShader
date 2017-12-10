// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "Zephyr/BlinnPhongTextureCartoon"
{
	Properties{
		_Color("Color", Color) = (1,1,1,1)
        _MainTex("Main Tex", 2D) = "white"{}
        _Specular("Specular", Color) = (1,1,1,1)
        _Gloss("Gloss", Range(8,256)) = 20
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

			fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _Specular;
            float _Gloss;
            int _Floors;

			struct a2v{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
                float4 texcoord : TEXCOORD0;
			};

			struct v2f{
				float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
				float3 worldPos : TEXCOORD1;
                float2 uv : TEXCOORD2;
			};

			v2f vert(a2v v){
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);

				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

				return o;
			}

			fixed4 frag(v2f i) : SV_TARGET{                
                fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

                fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
                
                //将光线强度阶梯化
                float lightStrength = dot(worldNormal, worldLightDir)*0.5+0.5;
                float flooredLightStrenth = (float)(((int)(lightStrength*_Floors)))/_Floors;
                fixed3 diffuse = _LightColor0.rgb * albedo * flooredLightStrenth;

                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                fixed3 halfDir = normalize(viewDir + worldLightDir);

                //specular高光只留一阶
                float specularStrength = pow(saturate(dot(worldNormal, halfDir)), _Gloss);
                float flooredSpecularStrength = (float)(((int)(specularStrength*2)))/2;

                fixed3 specular = _LightColor0.rgb * _Specular.rgb * flooredSpecularStrength;
                
				return fixed4(ambient + diffuse + specular, 1);
			}

			ENDCG
		}
	}
}
