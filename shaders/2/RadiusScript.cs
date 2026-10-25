using UnityEngine;

[ExecuteInEditMode]
public class RadiusScript : MonoBehaviour
{
    public Material Radius;

    void Start()
    {

    }

    void Update()
    {
        if (Radius != null)
        {
            // 把 A 的位置传给 Shader
            Radius.SetVector("_Center", transform.position);
        }
    }
}