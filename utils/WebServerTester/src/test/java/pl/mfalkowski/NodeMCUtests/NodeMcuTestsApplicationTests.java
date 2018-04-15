package pl.mfalkowski.NodeMCUtests;

import org.junit.Test;
import org.junit.runner.RunWith;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.junit4.SpringRunner;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

@RunWith(SpringRunner.class)
@SpringBootTest
public class NodeMcuTestsApplicationTests {

	@Test
	public void contextLoads() {
	}


	@Test
	public void expandTest() {

		Mono.just("A")
			.expand(s ->
				Mono.just(s)
					.filter(ss -> ss.length() < 5)
					.flatMapMany(ss -> Flux.just(ss + "!", ss + "?"))
			)
			.subscribe(System.out::println);
	}

}
