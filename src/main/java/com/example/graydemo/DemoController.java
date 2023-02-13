package com.example.graydemo;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * <p>Creation Date: 2023-01-12 10:38</p >
 *
 * @author liujhtr
 * @version 1.0.0
 * @since Version 1.0.0
 */
@RestController
@RequestMapping("/demo")
public class DemoController {
    @GetMapping("test")
    public String get(){
        return "Hello World (Version：stable)";
    }
}
