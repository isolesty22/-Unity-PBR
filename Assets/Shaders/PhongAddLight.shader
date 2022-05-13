Shader "Unlit/PhongAddLight"
{
    Properties
    {
        _Color ("Color", Color) = (1,0,0,1)
        _Albedo("Albedo",2D) = "white"{}
        _Ambient ("Ambient", Range(0,1)) = 0.1
        //[Gamma] _Metalic("Metalic", Range(0,1)) = 0
        _Smoothness("Smoothness", Range(0,1)) = 0.5
    }
    SubShader
    {
        Pass
        {
            Tags { "LightMode"="ForwardBase" }
            LOD 100

            CGPROGRAM
            #pragma target 3.0
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityPBSLighting.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv :TEXCOORD0;
                float3 wNormal : TEXCOORD1;
                float4 wVertex : TEXCOORD2;
            };

            fixed4 _Color;
            sampler2D _Albedo;
            float4 _Albedo_ST;
            float _Ambient;
            float _Smoothness;
            //float _Metalic;

            v2f vert (appdata v)
            {
                v2f o;

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.wVertex = mul(unity_ObjectToWorld,v.vertex);
                o.wNormal = UnityObjectToWorldNormal(v.normal);
                o.uv =  TRANSFORM_TEX(v.uv, _Albedo);

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float4 tex = tex2D(_Albedo, i.uv);
                //energe conservation
                float3 albedo = tex * _Color;
                // albedo *= (1-_Specular.xyz);               
                // albedo = EnergyConservationBetweenDiffuseAndSpecular(albedo, _SpecularColor, oneMinusReflectivity);
                // float oneMinusReflectivity = 1-_Metalic;
                // albedo *= oneMinusReflectivity;
                // float3 specularTint = albedo *_Metalic;
                // float oneMinusReflectivity;
                // float3 specularTint;
                // albedo = DiffuseAndSpecularFromMetallic(albedo,_Metalic,specularTint,oneMinusReflectivity);

                float3 wNormal = normalize(i.wNormal);
                //float3 lightDir = _WorldSpaceLightPos0.xyz; //_WorldSpaceLightPos0 is already normalized
                float3 lightDir = normalize(UnityWorldSpaceLightDir(i.wVertex));
                //float3 viewDir = normalize(UnityWorldSpaceViewDir(i.wVertex));
                float3 viewDir = normalize(_WorldSpaceCameraPos - i.wVertex);

                UnityLight light;
				light.color = _LightColor0;
				light.dir = lightDir;
				light.ndotl = DotClamped(i.wNormal, lightDir);
                UnityIndirect indirectLight;
				indirectLight.diffuse = 0;
				indirectLight.specular = 0;
                
                //lambert diffuse
                float lambert = max(_Ambient,dot(lightDir,wNormal)); //max(0, dot(lightDir, wNormal)); //DotClamped() is dot - to +
                float4 diffuse = float4(albedo,1) * lambert * float4(light.color,1);

                //phong specular
                float3 reflectDir = reflect(-lightDir,wNormal);
                float3 VDotR = saturate(dot(viewDir,reflectDir));
                float3 phong = pow(VDotR, _Smoothness * 100);
                //float4 specular = float4(phong,1) * _LightColor0 * float4(specularTint,1);
                float4 specular = float4(phong,1) * float4(light.color,1);
                

                //final color
                float4 finalColor = diffuse + specular;

                return finalColor;
            }
            ENDCG
        }

        Pass
        {
            Tags { "LightMode"="ForwardAdd" }
            LOD 100
            Blend One One
            ZWrite Off

            CGPROGRAM
            #pragma target 3.0
            #pragma vertex vert
            #pragma fragment frag

            //#define POINT
            #pragma multi_compile DIRECTIONAL POINT SPOT

            #include "UnityPBSLighting.cginc"
            #include "AutoLight.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv :TEXCOORD0;
                float3 wNormal : TEXCOORD1;
                float4 wVertex : TEXCOORD2;
            };

            fixed4 _Color;
            sampler2D _Albedo;
            float4 _Albedo_ST;
            float _Ambient;
            float _Smoothness;
            //float _Metalic;

            v2f vert (appdata v)
            {
                v2f o;

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.wVertex = mul(unity_ObjectToWorld,v.vertex);
                o.wNormal = UnityObjectToWorldNormal(v.normal);
                o.uv =  TRANSFORM_TEX(v.uv, _Albedo);

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float4 tex = tex2D(_Albedo, i.uv);
                //energe conservation
                float3 albedo = tex * _Color;
                // albedo *= (1-_Specular.xyz);               
                // albedo = EnergyConservationBetweenDiffuseAndSpecular(albedo, _SpecularColor, oneMinusReflectivity);
                // float oneMinusReflectivity = 1-_Metalic;
                // albedo *= oneMinusReflectivity;
                // float3 specularTint = albedo *_Metalic;
                // float oneMinusReflectivity;
                // float3 specularTint;
                // albedo = DiffuseAndSpecularFromMetallic(albedo,_Metalic,specularTint,oneMinusReflectivity);

                //normalize
                float3 wNormal = normalize(i.wNormal);
                //float3 lightDir = _WorldSpaceLightPos0.xyz; //_WorldSpaceLightPos0 is already normalized
                //float3 lightDir = normalize(UnityWorldSpaceLightDir(i.wVertex));
                //float3 viewDir = normalize(UnityWorldSpaceViewDir(i.wVertex));
                float3 viewDir = normalize(_WorldSpaceCameraPos - i.wVertex);

                //light
                UnityLight light;
                #if defined(POINT) || defined(SPOT)
		        light.dir = normalize(UnityWorldSpaceLightDir(i.wVertex));
	            #else
	        	light.dir = _WorldSpaceLightPos0.xyz;
	            #endif
                //light.dir = normalize(UnityWorldSpaceLightDir(i.wVertex));
                // float3 lightDistance = _WorldSpaceLightPos0.xyz -i.wVertex.xyz;
                // float attenuation = 1 / dot(lightDistance,lightDistance);
                UNITY_LIGHT_ATTENUATION(attenuation,0,i.wVertex.xyz);
                light.color = _LightColor0.xyz * attenuation;
                light.ndotl = DotClamped(wNormal, light.dir);

                UnityIndirect indirectLight;
				indirectLight.diffuse = 0;
				indirectLight.specular = 0;
                
                //lambert diffuse
                float lambert = max(_Ambient,dot(light.dir,wNormal)); //max(0, dot(lightDir, wNormal)); //DotClamped() is dot - to +
                float4 diffuse = float4(albedo,1) * lambert * float4(light.color,1);

                //phong specular
                float3 reflectDir = reflect(-light.dir,wNormal);
                float3 VDotR = saturate(dot(viewDir,reflectDir));
                float3 phong = pow(VDotR, _Smoothness * 100);
                //float4 specular = float4(phong,1) * _LightColor0 * float4(specularTint,1);
                float4 specular = float4(phong,1) * float4(light.color,1);
                

                //final color
                float4 finalColor = diffuse + specular;

                return finalColor;
            }
            ENDCG
        }
    }
}
