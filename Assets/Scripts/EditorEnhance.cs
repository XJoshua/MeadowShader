using System;
using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

public static class EditorEnhance
{
    [MenuItem("EditorEnhance/ScreenShot")]
    static void ScreenShot()
    {
        string name = DateTime.Now.ToString("HH_mm_ss") + "_" + (int)(UnityEngine.Random.value * 100) + ".jpg";
        //Debug.Log(name);
        ScreenCapture.CaptureScreenshot(
            string.Format(@"D:\02 Work\00-Working\GitRepo\GithubBlog\img\in-post\1810\" + name));
    }

}
