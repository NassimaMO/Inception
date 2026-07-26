NAME = inception

VOLUMES = /home/nnassiri/data

DOCKER_COMPOSE_PATH = srcs/docker-compose.yml

all: $(NAME)

$(NAME): build up

build:
	mkdir -p /home/nnassiri/data/wp /home/nnassiri/data/db
	docker compose -f ${DOCKER_COMPOSE_PATH} build

up:
	docker compose -f ${DOCKER_COMPOSE_PATH} up -d

down:
	docker compose -f ${DOCKER_COMPOSE_PATH} down

state:
	docker compose -f ${DOCKER_COMPOSE_PATH} ps

network:
	docker network ls
	docker network inspect inception

volumes:
	docker volume ls

clean: down
	docker system prune -af

fclean: clean
	docker system prune -af --volumes
	sudo rm -rf ${VOLUMES}

re: fclean all

.PHONY: all clean fclean re state network volumes
