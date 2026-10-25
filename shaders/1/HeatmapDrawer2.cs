using UnityEngine;

public class HeatmapDrawer2 : MonoBehaviour
{
    public Vector4[] positions;
    public float[] radiuses;
    public float[] intensities;
    public Material material;

    // 用于判断是否需要更新数据
    private Vector4[] lastPositions;
    private float[] lastRadiuses;
    private float[] lastIntensities;

    void Start()
    {
        UpdateHeatData();
    }

    void Update()
    {
        // 只有数据改变时才更新
        if (DataChanged())
        {
            UpdateHeatData();
        }

        // 实时同步
        ApplyBreathingEffect(); // 呼吸灯效果
    }

    // 判断数据是否变化
    bool DataChanged()
    {
        if (lastPositions == null || positions == null) return true;
        if (lastPositions.Length != positions.Length) return true;

        for (int i = 0; i < positions.Length; i++)
        {
            if (lastPositions[i] != positions[i]) return true;
            if (lastRadiuses[i] != radiuses[i]) return true;
            if (lastIntensities[i] != intensities[i]) return true;
        }
        return false;
    }

    // 传递数据给Shader
    void UpdateHeatData()
    {
        material.SetInt("_Points_Length", positions.Length);
        material.SetVectorArray("_Points", positions);

        Vector4[] properties = new Vector4[positions.Length];
        for (int i = 0; i < positions.Length; i++)
        {
            properties[i] = new Vector2(radiuses[i], intensities[i]);
        }
        material.SetVectorArray("_Properties", properties);

        lastPositions = (Vector4[])positions.Clone();
        lastRadiuses = (float[])radiuses.Clone();
        lastIntensities = (float[])intensities.Clone();
    }

    // 呼吸灯效果（大小 & 亮度随时间变化）
    void ApplyBreathingEffect()
    {
        for (int i = 0; i < intensities.Length; i++)
        {
            float pulse = Mathf.Sin(Time.time * 2f) * 0.5f + 0.5f;
            intensities[i] = pulse * 0.8f + 0.2f;
        }
    }
}