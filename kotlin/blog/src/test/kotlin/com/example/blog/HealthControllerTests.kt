package com.example.blog

import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.context.SpringBootTest
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc
import org.springframework.test.web.servlet.MockMvc
import org.springframework.test.web.servlet.get

@SpringBootTest
@AutoConfigureMockMvc
class HealthControllerTests(@Autowired val mockMvc: MockMvc) {

	@Test
	fun `GET healthcheck returns status ok`() {
		mockMvc.get("/api/v1/healthcheck").andExpect {
			status { isOk() }
			jsonPath("$.status") { value("ok") }
		}
	}
}
