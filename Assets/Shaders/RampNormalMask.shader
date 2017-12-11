// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "Zephyr/RampNormalMask"
{
	Properties{
		_Color("Color", Color) = (1,1,1,1)
        _MainTex("Main Tex", 2D) = "white" {}
		_BumpTex("Normal Map", 2D) = "white" {}
		_BumpScale("Bump Scale", Float) = 1 
		_RampTex("Ramp Tex", 2D) = "white" {}
		_SpecularMask("Specular Mask", 2D) = "white" {}
		_SpecularScale("Specular Scale", Float) = 1
        _Specular("Specular", Color) = (1,1,1,1)
        _Gloss("Gloss", Range(8,256)) = 20
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
			sampler2D _BumpTex;
            float _BumpScale;
			sampler2D _RampTex;
			sampler2D _SpecularMask;
			float _SpecularScale;
            fixed4 _Specular;
            float _Gloss;

			struct a2v{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 tangent: TANGENT;
                float4 texcoord : TEXCOORD0;
			};

			struct v2f{
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
                float3 lightDir : TEXCOORD1;
				float3 viewDir : TEXCOORD2;
                
			};

			v2f vert(a2v v){
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
				TANGENT_SPACE_ROTATION;
				o.lightDir = mul(rotation, ObjSpaceLightDir(v.vertex)).xyz;
				o.viewDir = mul(rotation, ObjSpaceViewDir(v.vertex)).xyz;

				return o;
			}

			fixed4 frag(v2f i) : SV_TARGET{
				fixed3 tangentLightDir = normalize(i.lightDir);
				fixed3 tangentViewDir = normalize(i.viewDir);

				fixed3 tangentNormal = UnpackNormal(tex2D(_BumpTex, i.uv));
				tangentNormal.xy *= _BumpScale;
				tangentNormal.z = sqrt(1-saturate(dot(tangentNormal.xy, tangentNormal.xy)));

                fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
                
                //将光线强度按ramp修正
                float lightStrength = dot(tangentNormal, tangentLightDir)*0.5+0.5;
				fixed3 ramp = tex2D(_RampTex, fixed2(lightStrength, lightStrength)).rgb;
                fixed3 diffuse = _LightColor0.rgb * albedo * ramp;

                fixed3 halfDir = normalize(tangentLightDir + tangentViewDir);
				//specular 遮罩纹理
				fixed specularMask = tex2D(_SpecularMask, i.uv).r * _SpecularScale;
                float specularStrength = pow(saturate(dot(tangentNormal, halfDir)), _Gloss);
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * specularStrength * specularMask;
                
				return fixed4(ambient + diffuse + specular, 1);
			}

			ENDCG
		}
	}
}
