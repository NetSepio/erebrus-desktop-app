<template>
    <div class="background-container">
        <div class="hello-world">
            <div class="flex">
                <img src="@/assets/arrow-left-windows.svg" @click="goHome" title="Home"
                        style="height: 30px; cursor: pointer;" />
                <h1>My Wallet</h1>
                <h1></h1>
            </div>
            <div>
                <h2>Back Up Mnemonics</h2>
                <div class="box">
                    <div class="grid">
                        <div v-for="(word, index) in words" :key="index" class="grid-item">
                            <span class="number">{{ index + 1 }}.</span>
                            <span class="word">{{ word }}</span>
                        </div>
                    </div>
                </div>
            </div>
            <div>
                <div style="height: 40px" />
                <button class="slave">Next</button>
            </div>
        </div>
    </div>
</template>

<script>
export default {
    data() {
        return {
            words: [
                "thrive", "issue", "moment", "vision", "effort",
                "journey", "growth", "future", "passion",
                "impact", "success", "change"
            ]
        };
    },
    methods: {
        goHome() {
            this.$router.push('/'); // Navigate to home route
        }
    }
};
</script>

<style scoped>
.background-container {
  position: relative;
  height: 100vh
}

.background-container::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: url('@/assets/seed_background.webp') no-repeat center center;
  background-size: cover;
  opacity: 0.08;
  z-index: -1;
}
.flex {
    display: flex;
    justify-content: space-between;
    align-items: center;
}

.hello-world {
    width: 80%;
    margin: 0 auto;
}

.hello-world h1 {
    text-align: center;
}

.box {
    width: auto;
    padding: 40px;
    border: 2px solid #333;
    border-radius: 10px;
    display: flex;
    justify-content: center;
}

.grid {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 50px;
}

.grid-item {
    display: flex;
    align-items: center;
    text-align: left;
}

.number {
    font-size: 14px;
    font-weight: bold;
    margin-right: 5px;
    color: #666;
}

.word {
    font-size: 18px;
    font-weight: bold;
}
</style>